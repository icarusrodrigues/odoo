FROM python:3.12-slim-bookworm

# Definir variáveis de ambiente
ENV DEBIANFRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# 1. Dependências do sistema (adicionado libx11-6, libxcb1, libxext6, libxrender1, xfonts-75dpi)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libssl-dev \
    libffi-dev \
    libxml2-dev \
    libxslt1-dev \
    zlib1g-dev \
    libsasl2-dev \
    libldap2-dev \
    libpq-dev \
    libjpeg-dev \
    git \
    wget \
    fontconfig \
    libx11-6 \
    libxcb1 \
    libxext6 \
    libxrender1 \
    xfonts-75dpi \
    xfonts-base \
    && rm -rf /var/lib/apt/lists/*

# 2. Instalação do wkhtmltopdf com verificação de dependências
RUN wget -q https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/wkhtmltox_0.12.6.1-3.bookworm_amd64.deb \
    && apt-get update \
    && apt-get install -y --no-install-recommends ./wkhtmltox_0.12.6.1-3.bookworm_amd64.deb \
    && rm wkhtmltox_0.12.6.1-3.bookworm_amd64.deb \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/odoo

# 3. Baixa o código-fonte do Odoo 18
RUN git clone https://github.com/odoo/odoo.git --depth 1 --branch 18.0 /opt/odoo/odoo-core

# 4. Instala as dependências Python
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r /opt/odoo/odoo-core/requirements.txt

# Cria usuário para segurança (Odoo não deve rodar como root)
RUN useradd -ms /bin/bash odoo && \
    mkdir -p /var/lib/odoo /etc/odoo /mnt/extra-addons && \
    chown -R odoo:odoo /opt/odoo /var/lib/odoo /etc/odoo /mnt/extra-addons

# Copia configurações (Certifique-se de que o odoo.conf existe localmente)
COPY ./odoo.conf /etc/odoo/odoo.conf
RUN chown odoo:odoo /etc/odoo/odoo.conf

USER odoo

EXPOSE 8069 8072

ENTRYPOINT ["python3", "/opt/odoo/odoo-core/odoo-bin", "-c", "/etc/odoo/odoo.conf"]