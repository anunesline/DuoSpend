# Sprint 28 — Scanner Fiscal

O Scanner Fiscal produz somente um `ReceiptTransactionDraft` temporário. OCR,
QR e edição manual não persistem nem movimentam dados financeiros. A criação
só ocorre depois da confirmação explícita na Nova Transação, pelo fluxo
financeiro existente.

## Limitação conhecida de QR fiscal

O aplicativo lê e valida o código QR fiscal e possui a interface de consulta
estruturada isolada por provider. A consulta automática de NFC-e/CF-e ainda
depende de um provider específico por UF/portal fiscal; ela não foi acoplada
nesta sprint para evitar scraping frágil no domínio. Enquanto não houver esse
provider, a experiência informa a indisponibilidade e mantém o fallback de OCR
funcional, além da revisão manual.

### Avaliação técnica

Não há uma API pública nacional, estável e sem credenciais que receba qualquer
URL/chave de QR de NFC-e/CF-e e devolva os itens da nota em formato estruturado.
As consultas públicas são descentralizadas por UF: podem expor apenas uma página
de consumidor, variar a URL do QR ou exigir desafio anti-automação. Os
webservices fiscais oficiais são voltados ao emissor e normalmente exigem
credenciamento/certificado. Portanto, uma integração genérica nesta camada
seria scraping frágil e não foi implementada.

Falha, indisponibilidade ou ausência de provider retorna `unavailable`; nunca
impede o usuário de fotografar a nota, usar OCR ou corrigir manualmente. Um
provider futuro deve morar em `data/providers`, atender apenas os portais para
os quais exista contrato/API autorizada e normalizar a resposta em
`ReceiptScanResult`.

### Paraná

O QR oficial da NFC-e/PR é reconhecido pelo `ParanaFiscalQrLookupProvider`
(host e parâmetros oficiais). A SEFA/PR documenta a URL e a composição do QR,
mas a consulta pública disponível é uma página de consumidor; não há payload
JSON/XML de nota e itens documentado para integração por aplicativo. O provider
portanto retorna `null` deliberadamente, mantendo OCR/revisão manual. Ele não
faz scraping da página HTML e é o ponto isolado para uma futura API autorizada.
