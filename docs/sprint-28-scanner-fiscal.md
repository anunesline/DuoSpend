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
