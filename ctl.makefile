PWD:=$(shell pwd)

# 可取消注释来使用自定义目录，否则使用当前目录来安装虚拟环境
#VENV_BASE=$(shell eval echo ~$$USER)
VENV_BASE?=$(PWD)
VENV_PATH=$(VENV_BASE)/searx-pyenv

# 可取消注释来使用自定义目录，否则在当前目录安装注释文件
#CONFIG_BASE=/etc/searx
CONFIG_BASE?=$(PWD)
SETTINGS_PATH=$(CONFIG_BASE)/settings.yml

PORT=
PID=

ifeq ($(wildcard $(VENV_PATH)/bin/activate),)
INSTALL_ENV_IF_NEEDED=install-pyenv
endif

ifeq ($(wildcard $(SETTINGS_PATH)),)
CONFIG_IF_NEEDED=config
else
PORT=$(shell cat $(SETTINGS_PATH) | grep port | awk -F ':' '{print $$2}' | awk '{gsub(/^\s+|\s+$$/, "");print}')
PID=$(shell lsof -t -i :$(PORT))
endif

.PHONY: start
start: prelude
	. $(VENV_PATH)/bin/activate \
		&& export SEARX_SETTINGS_PATH=$(SETTINGS_PATH) \
		&& python searx/webapp.py >> $(PWD)/runtime.log 2>&1

.PHONY: stop
stop:
	kill $(PID)

.PHONY: check
check: prelude
	@echo venv = $(VENV_PATH)
	@echo settings = $(SETTINGS_PATH)
	@echo port = $(PORT)
	@echo pid = $(PID)

.PHONY: prelude
prelude: $(INSTALL_ENV_IF_NEEDED) $(CONFIG_IF_NEEDED)

.PHONY: install-pyenv
install-pyenv:
	#sudo -H apt-get install -y \
	#python3-dev python3-babel python3-venv \
	#uwsgi uwsgi-plugin-python3 \
	#git build-essential libxslt-dev zlib1g-dev libffi-dev libssl-dev \
	#shellcheck

	# 在当前目录下创建虚拟环境：
	python3 -m venv $(VENV_PATH)

	# 安装依赖包
	. $(VENV_PATH)/bin/activate \
	&& pip install -U pip \
	&& pip install -U setuptools \
	&& pip install -U wheel \
	&& pip install -U pyyaml \
	&& pip install -e .

.PHONY: config
config:
	cp $(PWD)/utils/templates/etc/searx/use_default_settings.yml $(SETTINGS_PATH)
	sed -i -e "s/ultrasecretkey/$$(openssl rand -hex 16)/g" $(SETTINGS_PATH)
