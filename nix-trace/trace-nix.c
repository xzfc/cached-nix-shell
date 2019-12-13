#define _GNU_SOURCE

#include <dirent.h>
#include <dlfcn.h>
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <pthread.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

static pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;
static int log_fd = -1;

static int (*old__xstat)(int ver, const char *path, struct stat *buf) = NULL;
static int (*old__xstat64)(int ver, const char *path, struct stat64 *buf) = NULL;
static int (*old__lxstat)(int ver, const char *path, struct stat *buf) = NULL;
static int (*old__lxstat64)(int ver, const char *path, struct stat64 *buf) = NULL;
static int (*oldopen)(const char *pathname, int flags, ...) = NULL;
static DIR *(*oldopendir)(const char *name) = NULL;

#define PASS(FUN, ...) \
	if (old##FUN == NULL) \
		old##FUN = dlsym(RTLD_NEXT, #FUN); \
	return old##FUN(__VA_ARGS__);

static void print_log(const char *path) {
	if (log_fd == -1)
		return;

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
			return;
	for (const char **p = ignored_prefices; *p; p++)
		if (!memcmp(path, *p, strlen(*p)))
			return;

	pthread_mutex_lock(&mutex);
	dprintf(log_fd, "%s%c", path, (char)0);
	pthread_mutex_unlock(&mutex);
}

static void __attribute__((constructor)) init() {
	// Remove ourselves from LD_PRLOAD. We do not want to log child processes.
	// TODO: use `ld.so --preload` instead
	unsetenv("LD_PRELOAD");

	const char *fd_s = getenv("TRACE_NIX_FD");
	if (fd_s != NULL) {
		char *endptr = NULL;
		long l = strtol(fd_s, &endptr, 10);
		errno = 0;
		if (*endptr == 0 && l >= 0 && l <= INT_MAX && fcntl(l, F_GETFD) != -1) {
			log_fd = l;
		} else {
			fprintf(stderr, "trace-nix: invalid descriptor TRACE_NIX_FD=%s\n", fd_s);
		}
	}
	unsetenv("TRACE_NIX_FD");
}

int __xstat(int ver, const char *path, struct stat *buf) {
	print_log(path);
	PASS(__xstat, ver, path, buf);
} 

int __xstat64(int ver, const char *path, struct stat64 *buf) {
	print_log(path);
	PASS(__xstat64, ver, path, buf);
}

int __lxstat(int ver, const char *path, struct stat *buf) {
	print_log(path);
	PASS(__lxstat, ver, path, buf);
} 

int __lxstat64(int ver, const char *path, struct stat64 *buf) {
	print_log(path);
	PASS(__lxstat64, ver, path, buf);
}

int open(const char *pathname, int flags, ...) {
	print_log(pathname);

	va_list args;
	va_start(args, flags);
	int mode = va_arg(args, int);
	va_end(args);

	PASS(open, pathname, flags, mode);
}

DIR *opendir(const char *name) {
	print_log(name);
	PASS(opendir, name);
}
