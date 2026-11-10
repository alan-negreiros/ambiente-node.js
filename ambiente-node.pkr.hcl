# 1. Plugin: ensina o Packer a conversar com o Docker
packer {
  required_plugins {
    docker = {
      version = ">= 1.0.8"
      source  = "github.com/hashicorp/docker"
    }
  }
}

# 2. Fonte: imagem base e commit do contêiner como imagem final
source "docker" "ubuntu" {
  image  = "ubuntu:jammy"
  commit = true

  # O Packer sobe o contêiner temporário com --entrypoint=/bin/sh.
  # Definir o ENTRYPOINT aqui evita que esse valor fique na imagem final,
  # assim "docker run ambiente-node:v1 node --version" ou "... bash" funcionam.
  changes = [
    "WORKDIR /app",
    "ENTRYPOINT [\"/usr/bin/env\"]",
    "CMD [\"node\"]"
  ]
}

# 3. Construção: os provisioners rodam na ordem em que aparecem
build {
  name    = "ambiente-node"
  sources = ["source.docker.ubuntu"]

  # Passo 1: instalar o Node.js e o npm
  provisioner "shell" {
    environment_vars = ["DEBIAN_FRONTEND=noninteractive"]
    inline = [
      "apt-get update",
      "apt-get install -y nodejs npm",
      "apt-get clean",
      "rm -rf /var/lib/apt/lists/*",
      "node --version",
      "npm --version"
    ]
  }

  # Passo 2: criar a pasta /app antes de copiar o arquivo para ela
  provisioner "shell" {
    inline = ["mkdir -p /app"]
  }

  # Passo 3: copiar o package.json local para /app
  provisioner "file" {
    source      = "${path.root}/package.json"
    destination = "/app/package.json"
  }

  # Passo 4: rodar o npm install dentro de /app
  provisioner "shell" {
    inline = ["cd /app && npm install"]
  }

  # 4. Etiqueta: nome e versão da imagem final
  post-processor "docker-tag" {
    repository = "ambiente-node"
    tags       = ["v1"]
  }
}
