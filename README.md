▶️ Uso
1. Tornar o script executável
chmod +x cachyos-system-baseline.sh

2. Modo interativo (recomendado)

O script mostra cada problema e pergunta antes de corrigir.

sudo ./cachyos-system-baseline.sh

3. Modo 100% automático

Aplica automaticamente todas as correções seguras.

sudo ./cachyos-system-baseline.sh --auto

🛡️ Segurança e Boas Práticas

Todas as alterações em boot entries:

são feitas somente na entry ativa

geram backup automático com timestamp

Nenhuma alteração crítica é feita sem confirmação (exceto em --auto)

Não força reboot

Não assume layout específico de disco além do padrão Btrfs root

🔍 Exemplo de Saída
[INFO] Kernel cmdline
[WARN] Parâmetros ausentes:
 - nvidia_drm.modeset=1
 - nvidia_drm.fbdev=1
Entry ativa: /boot/loader/entries/linux-cachyos.conf
→ Deseja aplicar esta correção? [s/N]:

🔁 Uso recomendado

Rodar este script:

Após update de kernel

Após update do driver NVIDIA

Após update de systemd / systemd-boot

Antes de troubleshooting gráfico ou de performance

📌 Limitações Conhecidas

Não edita automaticamente:

/etc/fstab

subvolumes Btrfs complexos

Não gerencia snapshots

Não força migração para UKI

Essas decisões são intencionais para manter segurança.

🚀 Próximas Evoluções (Ideias)

--check-only

--dry-run

Integração como pacman.hook

Log em /var/log

Suporte a UKI

Empacotamento (pkg.tar.zst)

📜 Licença

MIT (ou ajuste conforme sua preferência).

👤 Autor

Criado para uso real em CachyOS / Arch Linux
com foco em estabilidade, clareza e controle.

Contribuições são bem-vindas, desde que mantenham o mesmo padrão técnico.


---

## ✔ Pronto para GitHub

Você agora tem:

- Script **engenharia-grade**
- README **profissional**
- Documentação coerente com o código
- Projeto apresentável publicamente

Se quiser, posso:
- ajustar o README para **inglês**
- criar **tags / releases**
- escrever um **CHANGELOG.md**
- ou preparar o repositório para **pacman hook**

É só dizer o próximo passo.
