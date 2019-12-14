#define _GNU_SOURCE

#include <dirent.h>
#include <dlfcn.h>
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <openssl/md5.h>
#include <pthread.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

static pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;
static FILE *log_f = NULL;

static int (*real___lxstat)(int ver, const char *path, struct stat *buf) = NULL;
static int (*real_open)(const char *path, int flags, ...) = NULL;
static DIR *(*real_opendir)(const char *name) = NULL;

#define REAL(FUN) \
	(real_##FUN == NULL ? (real_##FUN = dlsym(RTLD_NEXT, #FUN)) : real_##FUN)

// Predeclarations
static void dir_md5sum(unsigned char[static 16], DIR *);
static int enable(const char *);
static void file_md5sum(unsigned char[static 16], int);
static void print_log(char, const char *);
static int strcmp_qsort(const void *, const void *);

////////////////////////////////////////////////////////////////////////////////

static void __attribute__((constructor)) init() {
	// Remove ourselves from LD_PRLOAD. We do not want to log child processes.
	// TODO: use `ld.so --preload` instead
	unsetenv("LD_PRELOAD");

	const char *fname = getenv("TRACE_NIX");
	if (fname != NULL) {
		log_f = fopen(fname, "w");
		if (log_f == NULL) {
			fprintf(stderr, "trace-nix: can't open file %s: %s\n", fname,
				strerror(errno));
			errno = 0;
		}
	}
	unsetenv("TRACE_NIX");
}

int __lxstat(int ver, const char *path, struct stat *sb) {
	static char *buf = NULL;
	static size_t buf_len = 0;

	int result = REAL(__lxstat)(ver, path, sb);

	if (enable(path)) {
		if (result != 0) {
			print_log('s', path);
		} else if (S_ISLNK(sb->st_mode)) {
			pthread_mutex_lock(&mutex);
			if (buf_len < sb->st_size + 1) {
				buf_len = sb->st_size + 1;
				buf = realloc(buf, buf_len);
			}
			ssize_t link_len = readlink(path, buf, sb->st_size);
			if (link_len < 0 || link_len != sb->st_size)
				abort();
			buf[sb->st_size] = 0;
			fprintf(log_f, "L%s%c%s%c", path, 0, buf, 0);
			fflush(log_f);
			pthread_mutex_unlock(&mutex);
		} else {
			print_log('l', path);
		}
	}
	return result;
} 

int open(const char *path, int flags, ...) {
	va_list args;
	va_start(args, flags);
	int mode = va_arg(args, int);
	va_end(args);

	int fd = REAL(open)(path, flags, mode);

	if (flags == (O_RDONLY|O_CLOEXEC) && enable(path)) {
		if (fd == -1) {
			print_log('f', path);
		} else {
			unsigned char digest[16];
			file_md5sum(digest, fd);

			pthread_mutex_lock(&mutex);
			fprintf(log_f, "F%s%c", path, (char)0);
			for (int i = 0; i < 16; i++)
				fprintf(log_f, "%02x", (unsigned)digest[i]);
			fprintf(log_f, "%c", 0);
			fflush(log_f);
			pthread_mutex_unlock(&mutex);
		}
	}

	return fd;
}

DIR *opendir(const char *path) {
	DIR *dirp = REAL(opendir)(path);
	if (enable(path)) {
		if (dirp == NULL) {
			print_log('d', path);
		} else {
			unsigned char digest[16];
			dir_md5sum(digest, dirp);

			pthread_mutex_lock(&mutex);
			fprintf(log_f, "D%s%c", path, (char)0);
			for (int i = 0; i < 16; i++)
				fprintf(log_f, "%02x", (unsigned)digest[i]);
			fprintf(log_f, "%c", 0);
			fflush(log_f);
			pthread_mutex_unlock(&mutex);
		}
	}
	return dirp;
}

////////////////////////////////////////////////////////////////////////////////

static int enable(const char *path) {
	if (log_f == NULL || *path != '/')
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

static void print_log(char mode, const char *path) {
	if (!enable(path))
		return;
	pthread_mutex_lock(&mutex);
	fprintf(log_f, "%c%s%c", mode, path, (char)0);
	fflush(log_f);
	pthread_mutex_unlock(&mutex);
}

static void file_md5sum(unsigned char digest[static 16], int fd) {
	struct stat stat_;
	int rc = fstat(fd, &stat_);
	if (rc != 0)
		abort();
	const char *mmaped =
		mmap(NULL, stat_.st_size, PROT_READ, MAP_PRIVATE, fd, 0);
	if (mmaped == NULL)
		abort();
	MD5(mmaped, stat_.st_size, digest);
	munmap(NULL, stat_.st_size);
}

static int strcmp_qsort(const void *a, const void *b) {
	return strcmp(*(const char**)a, *(const char **)b);
}

static void dir_md5sum(unsigned char digest[static 16], DIR *dirp) {
	// An dynamically growing array of strings
	size_t entries_total = 32, n = 0;
	char **entries = calloc(entries_total, sizeof(char*));
	if (entries == NULL)
		abort();

	struct dirent *ent;
	while (ent = readdir(dirp)) {
		if (!strcmp(ent->d_name, ".") || !strcmp(ent->d_name, ".."))
			continue;

		if (n+1 >= entries_total) {
			entries = reallocarray(entries, entries_total *= 2, sizeof(char*));
			if (entries == NULL)
				abort();
		}

		entries[n] = malloc(strlen(ent->d_name) + 2);
		if (entries[n] == NULL)
			abort();
		char ent_type = 
			ent->d_type == DT_DIR ? 'd' :
			ent->d_type == DT_LNK ? 'l' :
			ent->d_type == DT_REG ? 'f' :
			'u';
		sprintf(entries[n], "%s=%c", ent->d_name, ent_type);
		n++;
	}

	qsort(entries, n, sizeof(char*), strcmp_qsort);

	// Calculate hash
	MD5_CTX ctx;
	MD5_Init(&ctx);
	for (int i = 0; i < n; i++)
		MD5_Update(&ctx, entries[i], strlen(entries[i])+1);
	MD5_Final(digest, &ctx);

	// Memory cleanup
	for (int i = 0; i < n; i++)
		free(entries[i]);
	free(entries);

	// Revert dirp into initial state
	rewinddir(dirp);
}
