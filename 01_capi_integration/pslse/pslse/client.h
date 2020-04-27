/*
 * Copyright 2014,2015 International Business Machines
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
#ifndef _CLIENT_H_
#define _CLIENT_H_

#include <pthread.h>
#include <stdint.h>

enum client_state {
	CLIENT_NONE,
	CLIENT_INIT,
	CLIENT_VALID
};

enum flush_state {
	FLUSH_NONE,
	FLUSH_PAGED,
	FLUSH_FLUSHING
};

struct client {
	int pending;
	int idle_cycles;
	int fd;
	int context;
	int abort;
	int timeout;
	enum flush_state flushing;
	enum client_state state;
	uint16_t max_irqs;
	char type;
	uint64_t wed;
	uint32_t mmio_offset;
	uint32_t mmio_size;
	void *mem_access;
	void *mmio_access;
	char *ip;
	pthread_t thread;
	struct client *_prev;
	struct client *_next;
};

void client_drop(struct client *client, int cycles, enum client_state state);

#endif				/* _CLIENT_H_ */
