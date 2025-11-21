<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class InvoiceController extends Controller
{
    public function create(Request $request): JsonResponse
    {
        $data = $request->validate([
            'seller_company' => 'required|string',
            'seller_vat'     => 'required|string|regex:/^BE[0-1][0-9]{9}$/', // BE + 10 digits
            'seller_street'  => 'required|string',
            'seller_postal'  => 'required|string',
            'seller_city'    => 'required|string',

            'buyer_name'     => 'required|string',
            'buyer_vat'      => 'required|string|regex:/^BE[0-1][0-9]{9}$/',
            'buyer_street'   => 'required|string',
            'buyer_postal'   => 'required|string',
            'buyer_city'     => 'required|string',

            'invoice_number' => 'required|string',
            'invoice_date'   => 'required|date',
            'due_date'       => 'required|date',
            'buyer_reference' => 'required|string',

            'description'    => 'required|string',
            'quantity'       => 'required|numeric',
            'price_ex_vat'   => 'required|numeric',
            'vat_rate'       => 'required|numeric',
        ]);

        $subtotal = round($data['quantity'] * $data['price_ex_vat'], 2);
        $vat      = round($subtotal * $data['vat_rate'] / 100, 2);
        $total    = $subtotal + $vat;

        // Extract 10-digit enterprise number (without BE prefix)
        $sellerEnterprise = substr($data['seller_vat'], 2); // BE0777856345 → 0777856345
        $buyerEnterprise = substr($data['buyer_vat'], 2);  // BE0123456789 → 0123456789

        $xml = <<<XML
<?xml version="1.0" encoding="UTF-8"?>
<Invoice xmlns="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2"
         xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"
         xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2">
    <cbc:CustomizationID>urn:cen.eu:en16931:2017#compliant#urn:fdc:peppol.eu:2017:poacc:billing:3.0</cbc:CustomizationID>
    <cbc:ProfileID>urn:fdc:peppol.eu:2017:poacc:billing:01:1.0</cbc:ProfileID>
    <cbc:ID>{$data['invoice_number']}</cbc:ID>
    <cbc:IssueDate>{$data['invoice_date']}</cbc:IssueDate>
    <cbc:DueDate>{$data['due_date']}</cbc:DueDate>
    <cbc:InvoiceTypeCode>380</cbc:InvoiceTypeCode>
    <cbc:DocumentCurrencyCode>EUR</cbc:DocumentCurrencyCode>
    <cbc:BuyerReference>{$data['buyer_reference']}</cbc:BuyerReference>

    <!-- Supplier -->
    <cac:AccountingSupplierParty>
        <cac:Party>
            <cbc:EndpointID schemeID="0208">{$sellerEnterprise}</cbc:EndpointID>
            <cac:PartyName><cbc:Name>{$data['seller_company']}</cbc:Name></cac:PartyName>
            <cac:PostalAddress>
                <cbc:StreetName>{$data['seller_street']}</cbc:StreetName>
                <cbc:CityName>{$data['seller_city']}</cbc:CityName>
                <cbc:PostalZone>{$data['seller_postal']}</cbc:PostalZone>
                <cac:Country><cbc:IdentificationCode>BE</cbc:IdentificationCode></cac:Country>
            </cac:PostalAddress>
            <cac:PartyTaxScheme>
                <cbc:CompanyID>{$data['seller_vat']}</cbc:CompanyID>
                <cac:TaxScheme><cbc:ID>VAT</cbc:ID></cac:TaxScheme>
            </cac:PartyTaxScheme>
            <cac:PartyLegalEntity>
                <cbc:RegistrationName>{$data['seller_company']}</cbc:RegistrationName>
                <cbc:CompanyID schemeID="0208">{$sellerEnterprise}</cbc:CompanyID>
            </cac:PartyLegalEntity>
        </cac:Party>
    </cac:AccountingSupplierParty>

    <!-- Customer -->
    <cac:AccountingCustomerParty>
        <cac:Party>
            <cbc:EndpointID schemeID="0208">{$buyerEnterprise}</cbc:EndpointID>
            <cac:PartyName><cbc:Name>{$data['buyer_name']}</cbc:Name></cac:PartyName>
            <cac:PostalAddress>
                <cbc:StreetName>{$data['buyer_street']}</cbc:StreetName>
                <cbc:CityName>{$data['buyer_city']}</cbc:CityName>
                <cbc:PostalZone>{$data['buyer_postal']}</cbc:PostalZone>
                <cac:Country><cbc:IdentificationCode>BE</cbc:IdentificationCode></cac:Country>
            </cac:PostalAddress>
            <cac:PartyTaxScheme>
                <cbc:CompanyID>{$data['buyer_vat']}</cbc:CompanyID>
                <cac:TaxScheme><cbc:ID>VAT</cbc:ID></cac:TaxScheme>
            </cac:PartyTaxScheme>
            <cac:PartyLegalEntity>
                <cbc:RegistrationName>{$data['buyer_name']}</cbc:RegistrationName>
                <cbc:CompanyID schemeID="0208">{$buyerEnterprise}</cbc:CompanyID>
            </cac:PartyLegalEntity>
        </cac:Party>
    </cac:AccountingCustomerParty>

    <cac:PaymentMeans>
        <cbc:PaymentMeansCode name="Credit transfer">30</cbc:PaymentMeansCode>
        <cbc:PaymentID>{$data['invoice_number']}</cbc:PaymentID>
        <cac:PayeeFinancialAccount>
            <cbc:ID>BE68539007547034</cbc:ID>
        </cac:PayeeFinancialAccount>
    </cac:PaymentMeans>

    <cac:TaxTotal>
        <cbc:TaxAmount currencyID="EUR">{$vat}</cbc:TaxAmount>
        <cac:TaxSubtotal>
            <cbc:TaxableAmount currencyID="EUR">{$subtotal}</cbc:TaxableAmount>
            <cbc:TaxAmount currencyID="EUR">{$vat}</cbc:TaxAmount>
            <cac:TaxCategory>
                <cbc:ID>S</cbc:ID>
                <cbc:Percent>{$data['vat_rate']}</cbc:Percent>
                <cac:TaxScheme><cbc:ID>VAT</cbc:ID></cac:TaxScheme>
            </cac:TaxCategory>
        </cac:TaxSubtotal>
    </cac:TaxTotal>

    <cac:LegalMonetaryTotal>
        <cbc:LineExtensionAmount currencyID="EUR">{$subtotal}</cbc:LineExtensionAmount>
        <cbc:TaxExclusiveAmount currencyID="EUR">{$subtotal}</cbc:TaxExclusiveAmount>
        <cbc:TaxInclusiveAmount currencyID="EUR">{$total}</cbc:TaxInclusiveAmount>
        <cbc:PayableAmount currencyID="EUR">{$total}</cbc:PayableAmount>
    </cac:LegalMonetaryTotal>

    <cac:InvoiceLine>
        <cbc:ID>1</cbc:ID>
        <cbc:InvoicedQuantity unitCode="C62">{$data['quantity']}</cbc:InvoicedQuantity>
        <cbc:LineExtensionAmount currencyID="EUR">{$subtotal}</cbc:LineExtensionAmount>
        <cac:Item>
            <cbc:Description>{$data['description']}</cbc:Description>
            <cbc:Name>{$data['description']}</cbc:Name>
            <cac:ClassifiedTaxCategory>
                <cbc:ID>S</cbc:ID>
                <cbc:Percent>{$data['vat_rate']}</cbc:Percent>
                <cac:TaxScheme><cbc:ID>VAT</cbc:ID></cac:TaxScheme>
            </cac:ClassifiedTaxCategory>
        </cac:Item>
        <cac:Price>
            <cbc:PriceAmount currencyID="EUR">{$data['price_ex_vat']}</cbc:PriceAmount>
        </cac:Price>
    </cac:InvoiceLine>
</Invoice>
XML;

        return response()->json([
            'success' => true,
            'xml'     => $xml,
            'message' => 'PEPPOL BIS 3.0 invoice generated!',
        ]);
    }
}
