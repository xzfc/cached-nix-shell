#define _GNU_SOURCE

#include "blake3.h"
#include <dirent.h>
#include <dlfcn.h>
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

static FILE *log_f = NULL;
static const char *pwd = NULL;

#ifdef __APPLE__

struct dyld_interpose {
	const void * replacement;
	const void * replacee;
};

#define WRAPPER(RET, FUN) static RET _cns_wrapper_##FUN
#define REAL(FUN) FUN
#define DEF_WRAPPER(FUN) \
	__attribute__((used)) static struct dyld_interpose _cns_interpose_##FUN \
	__attribute__((section("__DATA,__interpose"))) = { &_cns_wrapper_##FUN, &FUN };

#else /* __APPLE__ */

static int (*real___lxstat)(int ver, const char *path, struct stat *buf) = NULL;
static int (*real_open)(const char *path, int flags, ...) = NULL;
static DIR *(*real_opendir)(const char *name) = NULL;

#define WRAPPER(RET, FUN) RET FUN
#define REAL(FUN) \
	(real_##FUN == NULL ? (real_##FUN = dlsym(RTLD_NEXT, #FUN)) : real_##FUN)
#define DEF_WRAPPER(FUN)

#endif /* __APPLE__ */

#define FATAL() \
	do { \
		fprintf(stderr, "nix-trace.c:%d: %s: %s\n", \
			__LINE__, __func__, strerror(errno)); \
		exit(2); \
	} while(0)

#define LEN 16

// Locks

#ifdef __APPLE__

#include <dispatch/dispatch.h>
static dispatch_semaphore_t print_mutex;
static dispatch_semaphore_t buf_mutex;
#define INIT_MUTEX(MUTEX) \
	MUTEX = dispatch_semaphore_create(1)
#define LOCK(MUTEX) \
	dispatch_semaphore_wait(MUTEX, DISPATCH_TIME_FOREVER)
#define UNLOCK(MUTEX) \
	dispatch_semaphore_signal(MUTEX)

#else /* __APPLE__ */

#include <pthread.h>
static pthread_mutex_t print_mutex = PTHREAD_MUTEX_INITIALIZER;
static pthread_mutex_t buf_mutex = PTHREAD_MUTEX_INITIALIZER;
#define INIT_MUTEX(MUTEX)
#define LOCK(MUTEX) \
	pthread_mutex_lock(&MUTEX)
#define UNLOCK(MUTEX) \
	pthread_mutex_unlock(&MUTEX)

#endif /* __APPLE__ */

// Predeclarations

static void print_stat(int result, const char *path, struct stat *sb);
static void convert_digest(char [static LEN*2+1], const uint8_t [static LEN]);
static int enable(const char *);
static void hash_dir(char [static LEN*2+1], DIR *);
static void hash_file(char [static LEN*2+1], int);
static void print_log(char, const char *, const char *);
static int strcmp_qsort(const void *, const void *);

////////////////////////////////////////////////////////////////////////////////

#ifdef __APPLE__

/*	$OpenBSD: reallocarray.c,v 1.3 2015/09/13 08:31:47 guenther Exp $	*/
/*
 * Copyright (c) 2008 Otto Moerbeek <otto@drijf.net>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#include <sys/types.h>
#include <errno.h>
#include <stdint.h>
#include <stdlib.h>

/*
 * This is sqrt(SIZE_MAX+1), as s1*s2 <= SIZE_MAX
 * if both s1 < MUL_NO_OVERFLOW and s2 < MUL_NO_OVERFLOW
 */
#define MUL_NO_OVERFLOW	((size_t)1 << (sizeof(size_t) * 4))

static void *reallocarray(void *optr, size_t nmemb, size_t size) {
	if ((nmemb >= MUL_NO_OVERFLOW || size >= MUL_NO_OVERFLOW) &&
		nmemb > 0 && SIZE_MAX / nmemb < size) {
		errno = ENOMEM;
		return NULL;
	}
	return realloc(optr, size * nmemb);
}

static const char *get_current_dir_name() {
	char *buf = NULL;
	size_t bufsize = 64 * sizeof(char);
	do {
		buf = realloc(buf, bufsize);
		if (buf == NULL)
			FATAL();
		if (getcwd(buf, bufsize))
		return buf;
		bufsize *= 2;
	} while (errno == ERANGE);
	FATAL();
}
#endif /* __APPLE__ */

static void __attribute__((constructor)) init() {
	// Remove ourselves from LD_PRELOAD and DYLD_INSERT_LIBRARIES. We do not want to log child processes.
	// TODO: use `ld.so --preload` instead
	unsetenv("LD_PRELOAD");
	unsetenv("DYLD_INSERT_LIBRARIES");

	const char *fname = getenv("TRACE_NIX");
	if (fname != NULL) {
		log_f = fopen(fname, "w");
		if (log_f == NULL) {
			fprintf(stderr, "trace-nix: can't open file %s: %s\n", fname,
				strerror(errno));
			errno = 0;
		}
		pwd = get_current_dir_name();
		if (pwd == NULL)
			FATAL();
	}
	unsetenv("TRACE_NIX");

	INIT_MUTEX(print_mutex);
	INIT_MUTEX(buf_mutex);
}

#ifdef __APPLE__

WRAPPER(int, lstat)(const char *path, struct stat *sb) {
	int result = REAL(lstat)(path, sb);
	print_stat(result, path, sb);
	return result;
}
DEF_WRAPPER(lstat);

#else /* __APPLE__ */

WRAPPER(int, __lxstat)(int ver, const char *path, struct stat *sb) {
	int result = REAL(__lxstat)(ver, path, sb);
	print_stat(result, path, sb);
	return result;
}
DEF_WRAPPER(__lxstat)

#endif /* __APPLE__ */

WRAPPER(int, open)(const char *path, int flags, ...) {
	va_list args;
	va_start(args, flags);
	int mode = va_arg(args, int);
	va_end(args);

	int fd = REAL(open)(path, flags, mode);

	if (flags == (O_RDONLY|O_CLOEXEC) && enable(path)) {
		if (fd == -1) {
			print_log('f', path, "-");
		} else {
			char digest[LEN*2+1];
			hash_file(digest, fd);
			print_log('f', path, digest);
		}
	}

	return fd;
}
DEF_WRAPPER(open)

WRAPPER(DIR *, opendir)(const char *path) {
	DIR *dirp = REAL(opendir)(path);
	if (enable(path)) {
		if (dirp == NULL) {
			print_log('d', path, "-");
		} else {
			char digest[LEN*2+1];
			hash_dir(digest, dirp);
			print_log('d', path, digest);
		}
	}
	return dirp;
}
DEF_WRAPPER(opendir)

////////////////////////////////////////////////////////////////////////////////

static int enable(const char *path) {
	if (log_f == NULL || (*path != '/' && strcmp(path, "shell.nix")))
		return 0;

	static const char *ignored_paths[] = {
		"/etc/ssl/certs/ca-certificates.crt",
		"/nix/var/nix/daemon-socket/socket",
		"/nix",
		"/nix/store",
		NULL,
	};
	static const char *ignored_prefices[] = {
		"/nix/store/", // assuming store paths are immutable
		"/nix/var/nix/temproots/",
		"/proc/",
		NULL,
	};
	for (const char **p = ignored_paths; *p; p++)
		if (!strcmp(path, *p))
			return 0;
	for (const char **p = ignored_prefices; *p; p++)
		if (!memcmp(path, *p, strlen(*p)))
			return 0;

	return 1;
}

static void print_stat(int result, const char *path, struct stat *sb) {
	static char *buf = NULL;
	static off_t buf_len = 0;

	if (enable(path)) {
		if (result != 0) {
			print_log('s', path, "-");
		} else if (S_ISLNK(sb->st_mode)) {
			LOCK(buf_mutex);
			if (buf_len < sb->st_size + 2) {
				buf_len = sb->st_size + 2;
				buf = realloc(buf, buf_len);
				if (buf == NULL)
					FATAL();
			}
			ssize_t link_len = readlink(path, buf+1, sb->st_size);
			if (link_len < 0 || link_len != sb->st_size)
				FATAL();
			buf[0] = 'l';
			buf[sb->st_size+1] = 0;
			print_log('s', path, buf);
						UNLOCK(buf_mutex);
		} else if (S_ISDIR(sb->st_mode)) {
			print_log('s', path, "d");
		} else {
			print_log('s', path, "+");
		}
	}
}

static void print_log(char op, const char *path, const char *result) {
	LOCK(print_mutex);
	fprintf(
		log_f,
		"%c" "%s%s" "%s%c" "%s%c",
		op,
		path[0] == '/' ? "" : pwd, path[0] == '/' ? "" : "/",
		path, (char)0,
		result, (char)0
	);
	fflush(log_f);
	UNLOCK(print_mutex);
}

static void hash_file(char digest_s[static LEN*2+1], int fd) {
	struct stat stat_;
	int rc = fstat(fd, &stat_);
	if (rc != 0)
		FATAL();
	char *mmaped = NULL;
	if (stat_.st_size != 0) {
		mmaped = mmap(NULL, stat_.st_size, PROT_READ, MAP_PRIVATE, fd, 0);
		if (mmaped == MAP_FAILED) {
			strcpy(digest_s, "e");
			return;
		}
	}

	blake3_hasher hasher;
	blake3_hasher_init(&hasher);
	blake3_hasher_update(&hasher, mmaped, stat_.st_size);
	uint8_t digest_b[LEN];
	blake3_hasher_finalize(&hasher, digest_b, LEN);
	convert_digest(digest_s, digest_b);

	if (stat_.st_size != 0) {
		rc = munmap(mmaped, stat_.st_size);
		if (rc != 0)
			FATAL();
	}
}

static int strcmp_qsort(const void *a, const void *b) {
	return strcmp(*(const char* const*)a, *(const char * const*)b);
}

static void hash_dir(char digest_s[static LEN*2+1], DIR *dirp) {
	// A dynamically growing array of strings
	size_t entries_total = 32, n = 0;
	char **entries = calloc(entries_total, sizeof(char*));
	if (entries == NULL)
		FATAL();

	struct dirent *ent;
	while ((ent = readdir(dirp))) {
		if (!strcmp(ent->d_name, ".") || !strcmp(ent->d_name, ".."))
			continue;

		if (n+1 >= entries_total) {
			entries = reallocarray(entries, entries_total *= 2, sizeof(char*));
			if (entries == NULL)
				FATAL();
		}

		char ent_type = 
			ent->d_type == DT_DIR ? 'd' :
			ent->d_type == DT_LNK ? 'l' :
			ent->d_type == DT_REG ? 'f' :
			'u';
		int l = asprintf(&entries[n++], "%s=%c", ent->d_name, ent_type);
		if (l == -1)
			FATAL();
	}

	qsort(entries, n, sizeof(char*), strcmp_qsort);

	// Calculate hash
	uint8_t digest_b[LEN];
	blake3_hasher hasher;
	blake3_hasher_init(&hasher);
	for (size_t i = 0; i < n; i++)
		blake3_hasher_update(&hasher, entries[i], strlen(entries[i])+1);
	blake3_hasher_finalize(&hasher, digest_b, LEN);
	convert_digest(digest_s, digest_b);

	// Memory cleanup
	for (size_t i = 0; i < n; i++)
		free(entries[i]);
	free(entries);

	// Revert dirp into initial state
	rewinddir(dirp);
}

static void convert_digest(char digest_s[static LEN*2+1], const uint8_t digest_b[static LEN]) {
	for (int i = 0; i < LEN; i++)
		sprintf(digest_s + i*2, "%02x", (unsigned)digest_b[i]);
}
