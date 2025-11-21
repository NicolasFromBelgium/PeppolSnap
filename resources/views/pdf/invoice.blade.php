<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <style>
        body { font-family: DejaVu Sans, sans-serif; font-size: 12pt; margin: 20px; }
        .header { text-align: center; border-bottom: 2px solid #000; padding-bottom: 10px; margin-bottom: 20px; }
        .party { margin-bottom: 20px; }
        .party th { width: 100px; text-align: left; }
        table { width: 100%; border-collapse: collapse; margin: 10px 0; }
        th, td { border: 1px solid #000; padding: 8px; text-align: left; }
        th { background-color: #f0f0f0; }
        .total { font-weight: bold; font-size: 14pt; }
    </style>
</head>
<body>
    <div class="header">
        <h1>PEPPOL Invoice {{ $data['invoice_number'] }}</h1>
        <p>Date: {{ $data['invoice_date'] }} | Due: {{ $data['due_date'] }}</p>
    </div>

    <table class="party">
        <tr><th>Seller</th><td>{{ $data['seller_company'] }}<br>VAT: {{ $data['seller_vat'] }}<br>{{ $data['seller_street'] }} {{ $data['seller_postal'] }} {{ $data['seller_city'] }}</td></tr>
    </table>

    <table class="party">
        <tr><th>Buyer</th><td>{{ $data['buyer_name'] }}
            @if(isset($data['buyer_vat']))<br>VAT: {{ $data['buyer_vat'] }}@endif
            @if(isset($data['buyer_street']))<br>{{ $data['buyer_street'] }} {{ $data['buyer_postal'] }} {{ $data['buyer_city'] }}@endif
        </td></tr>
    </table>

    <table>
        <thead>
            <tr><th>Description</th><th>Qty</th><th>Unit Price</th><th>VAT</th><th>Total</th></tr>
        </thead>
        <tbody>
            <tr>
                <td>{{ $data['description'] }}</td>
                <td>{{ $data['quantity'] }}</td>
                <td>€{{ number_format($data['price_ex_vat'], 2) }}</td>
                <td>{{ $data['vat_rate'] }}%</td>
                <td class="total">€{{ number_format($totalAmount, 2) }}</td>
            </tr>
        </tbody>
    </table>

    @if(!empty($data['seller_iban']))
        <p>Bank: IBAN {{ $data['seller_iban'] }}</p>
    @endif
</body>
</html>
