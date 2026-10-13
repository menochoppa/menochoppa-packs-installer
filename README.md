# menochoppa-packs-installer
Installer for Arrakis preset menochoppa Packs

## Instalar os seis presets

No terminal Linux do seu servidor, use somente este instalador. Ele tambem
prepara/atualiza o Arrakis original. Nao precisa executar os dois comandos.

```bash
read -rsp 'Token novo do Hugging Face: ' HF_TOKEN; echo
export HF_TOKEN
curl -fL https://raw.githubusercontent.com/menochoppa/menochoppa-packs-installer/codex/fix-presets-bootstrap/bootstrap_menochoppa_packs.sh -o /tmp/bootstrap_menochoppa_packs.sh && bash /tmp/bootstrap_menochoppa_packs.sh
```

Os presets sao gravados **depois** da atualizacao do repositorio original.
Uma exclusao local do Git protege os seis JSONs contra o `git stash` das
atualizacoes seguintes. Nenhum stash anterior e apagado ou aplicado.

O mesmo comando instala a compatibilidade do Impact Pack para o erro
`findInputSlot is not a function`. O bloco antigo que reconecta o slot zero e
sobrescreve o tipo da entrada e removido, com backup do JavaScript original.
Isso tambem evita um switch de texto receber o tipo INT de um widget.
A verificacao
acontece imediatamente e a cada inicio do ComfyUI por meio do custom node
`menochoppa_impact_compat`, inclusive depois de instalar ou atualizar os presets.
Se o trecho antigo nao existir, o JavaScript e preservado. Depois de executar
em uma instancia ja aberta, reinicie o ComfyUI pelo Arrakis e use Ctrl+F5 no
navegador antes de abrir o workflow original.

Se o seletor desse Arrakis ja estiver na porta 8090, o instalador o reaproveita;
atualize a pagina do seletor para ver os presets. Nenhum processo e encerrado.
Se outro servico ocupar essa porta, o instalador avisa e encerra sem mata-lo.
Para usar outra porta, execute `WEB_PORT=8091 bash /tmp/bootstrap_menochoppa_packs.sh`
e encaminhe a porta 8091 no painel VastAI/RunPod.

O instalador baixa o bootstrap original completo e adia sua inicializacao do
seletor em uma copia temporaria. Se a linha de inicializacao do original mudar,
o instalador aborta com uma mensagem em vez de executar uma versao desconhecida.
