# Technical prelude
SHELL := bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

COMPOSE := docker-compose
KAFKA_DIR := kafka
DRUID_DIR := druid
PRODUCER_DIR := producer

.PHONY: start-kafka
start-kafka:
	pushd "$(KAFKA_DIR)" && \
	$(COMPOSE) up -d && \
	popd

.PHONY: start-druid
start-druid:
	pushd "$(DRUID_DIR)" && \
	$(COMPOSE) up -d && \
	popd

.PHONY: start-producer
start-producer:
	pushd "$(PRODUCER_DIR)" && \
		bundle exec ruby bin/main.rb && \
		popd
