REPO_BACK := {{REPO_BACK_NAME}}
REPO_FRONT := {{REPO_FRONT_NAME}}
REPO_DATA := {{REPO_DATA_NAME}}

SETUP_TARGETS :=
TEST_TARGETS :=
LINT_TARGETS :=

.PHONY: help setup-all test-all lint-all

help:
	@echo "Local dev — commands aligned with dev-expert/approval agents"
	@echo ""
ifneq ($(REPO_BACK),)
	@echo "  make setup-back    Install $(REPO_BACK)"
endif
ifneq ($(REPO_FRONT),)
	@echo "  make setup-front   Install $(REPO_FRONT)"
endif
ifneq ($(REPO_DATA),)
	@echo "  make setup-data    Install $(REPO_DATA)"
endif
	@echo "  make setup-all     Install all repos"
	@echo ""
ifneq ($(REPO_BACK),)
	@echo "  make test-back     Build + test ($(REPO_BACK))"
endif
ifneq ($(REPO_FRONT),)
	@echo "  make test-front    Lint + build ($(REPO_FRONT))"
endif
ifneq ($(REPO_DATA),)
	@echo "  make test-data     Test ($(REPO_DATA))"
endif
	@echo "  make test-all      Run all tests"
	@echo ""
ifneq ($(REPO_BACK),)
	@echo "  make smoke-back    Start + health check"
endif
ifneq ($(REPO_FRONT),)
	@echo "  make smoke-front   Start dev server"
endif

ifneq ($(REPO_BACK),)
SETUP_TARGETS += setup-back
TEST_TARGETS += test-back
LINT_TARGETS += lint-back

setup-back:
	cd $(REPO_BACK) && {{BACK_SETUP_CMD}}

test-back:
	cd $(REPO_BACK) && {{BACK_LINT_CMD}} && {{BACK_BUILD_CMD}}

lint-back:
	cd $(REPO_BACK) && {{BACK_LINT_CMD}}

smoke-back:
	cd $(REPO_BACK) && {{BACK_START_CMD}}

.PHONY: setup-back test-back lint-back smoke-back
endif

ifneq ($(REPO_FRONT),)
SETUP_TARGETS += setup-front
TEST_TARGETS += test-front
LINT_TARGETS += lint-front

setup-front:
	cd $(REPO_FRONT) && {{FRONT_INSTALL_CMD}}

test-front:
	cd $(REPO_FRONT) && {{FRONT_INSTALL_CMD}} && {{FRONT_LINT_CMD}} && {{FRONT_BUILD_CMD}}

lint-front:
	cd $(REPO_FRONT) && {{FRONT_LINT_CMD}}

smoke-front:
	cd $(REPO_FRONT) && {{FRONT_START_CMD}}

.PHONY: setup-front test-front lint-front smoke-front
endif

ifneq ($(REPO_DATA),)
SETUP_TARGETS += setup-data
TEST_TARGETS += test-data
LINT_TARGETS += lint-data

setup-data:
	cd $(REPO_DATA) && {{DATA_SETUP_CMD}}

test-data:
	cd $(REPO_DATA) && {{DATA_SETUP_CMD}} && {{DATA_TEST_CMD}}

lint-data:
	cd $(REPO_DATA) && {{DATA_LINT_CMD}}

.PHONY: setup-data test-data lint-data
endif

setup-all: $(SETUP_TARGETS)

test-all: $(TEST_TARGETS)

lint-all: $(LINT_TARGETS)
