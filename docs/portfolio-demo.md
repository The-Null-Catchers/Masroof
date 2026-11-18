# Masroof Arabic portfolio month

The portfolio scenario uses a fresh test database and synthetic September 2026 transactions in ILS.

| Action | Bank | Wallet |
| --- | ---: | ---: |
| Deposit salary | 5,200.00 | 0.00 |
| Transfer 500.00 to the wallet | 4,700.00 | 500.00 |
| Resend the transfer with the same client ID | 4,700.00 | 500.00 |
| Review the receipt and confirm the corrected 84.75 expense | 4,700.00 | 415.25 |

The receipt upload uses the mock OCR provider. Its suggested amount of 24.40 leaves the balances untouched until the user confirms the corrected amount. A second confirmation returns HTTP 409. The 80.00 grocery budget is exceeded by 4.75. Monthly income is 5,200.00 and spending is 84.75. The transfer does not contribute to either total.

Run the scenario from `backend/` using the PostgreSQL test setup.

```sh
MASROOF_PORTFOLIO_PDF=/tmp/masroof-demo-month-ar.pdf php artisan test --filter PortfolioMonthTest
```

CI publishes the generated Arabic report in `masroof-portfolio-demo`. The automated scenario covers the shared API and PDF export. Web and mobile walkthroughs and actual Arabic OCR recognition remain separate checks.
