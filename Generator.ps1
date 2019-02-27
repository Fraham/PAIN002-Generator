param(
    [Parameter(Mandatory=$true)]
    $pain008File,
    [Parameter(Mandatory=$true)]
    $reasonCode,
    [Parameter(Mandatory=$true)]
    $reason,
    $generationId,
    $creationDate
)

$templateFile = "Template.txt"

if (!(Test-Path -path $templateFile -PathType Leaf)){
    Write-Error "Template does not exist"
    return
}

if (!(Test-Path -path $pain008File -PathType Leaf)){
    Write-Error "PAIN008 does not exist"
    return
}

[xml]$pain008 = Get-Content $pain008File

$pain002 = Get-Content $templateFile

$replaces = New-Object System.Collections.Generic.List[System.Object]

if ($null -eq $generationId){
    $generationId = $pain008.Document.CstmrDrctDbtInitn.GrpHdr.MsgId
}
if ($null -eq $creationDate){
    $creationDate = (Get-Date).ToString('u')
    git reset --hard HEAD^
}

$replaces.Add(@('*MessageId*', $generationId))
$replaces.Add(@('*CreationDateTime*', $creationDate))

$replaces.Add(@('*OriginalGroupFileNumber*', $pain008.Document.CstmrDrctDbtInitn.GrpHdr.MsgId))
$replaces.Add(@('*OriginalGroupNumberOfTransactions*', $pain008.Document.CstmrDrctDbtInitn.GrpHdr.NbOfTxs))
$replaces.Add(@('*OriginalGroupSum*', $pain008.Document.CstmrDrctDbtInitn.GrpHdr.CtrlSum))

$replaces.Add(@('*OriginalPmtNumberOfTransactions*', $pain008.Document.CstmrDrctDbtInitn.PmtInf.NbOfTxs))
$replaces.Add(@('*OriginalPmtSum*', $pain008.Document.CstmrDrctDbtInitn.PmtInf.CtrlSum))

$transactionId = $pain008.Document.CstmrDrctDbtInitn.PmtInf.DrctDbtTxInf.PmtId.EndToEndId
$replaces.Add(@('*EndToEndId*', $transactionId))

$replaces.Add(@('*ReasonCode*', $reasonCode))
$replaces.Add(@('*Reason*', $reason))

$replaces.Add(@('*Amount*', $pain008.Document.CstmrDrctDbtInitn.PmtInf.DrctDbtTxInf.InstdAmt.'#text'))
$replaces.Add(@('*RequestedCollectionDate*', $pain008.Document.CstmrDrctDbtInitn.PmtInf.ReqdColltnDt))

$replaces.Add(@('*SchemeId*', $pain008.Document.CstmrDrctDbtInitn.PmtInf.CdtrSchmeId.Id.PrvtId.Othr.Id))
$replaces.Add(@('*SchemeName*', $pain008.Document.CstmrDrctDbtInitn.PmtInf.CdtrSchmeId.Id.PrvtId.Othr.SchmeNm.Prtry))

$replaces.Add(@('*SequenceType*', $pain008.Document.CstmrDrctDbtInitn.PmtInf.PmtTpInf.SeqTp))

$replaces.Add(@('*MandateId*', $pain008.Document.CstmrDrctDbtInitn.PmtInf.DrctDbtTxInf.DrctDbtTx.MndtRltdInf.MndtId))
$replaces.Add(@('*DateOfSignature*', $pain008.Document.CstmrDrctDbtInitn.PmtInf.DrctDbtTxInf.DrctDbtTx.MndtRltdInf.DtOfSgntr))

$replaces.Add(@('*DebaterName*', $pain008.Document.CstmrDrctDbtInitn.PmtInf.DrctDbtTxInf.Dbtr.Nm))
$replaces.Add(@('*DebaterIban*', $pain008.Document.CstmrDrctDbtInitn.PmtInf.DrctDbtTxInf.DbtrAcct.Id.IBAN))
$replaces.Add(@('*DebaterBic*', $pain008.Document.CstmrDrctDbtInitn.PmtInf.DrctDbtTxInf.DbtrAgt.FinInstnId.BIC))

$replaces.Add(@('*CredaterName*', $pain008.Document.CstmrDrctDbtInitn.PmtInf.Cdtr.Nm))
$replaces.Add(@('*CredaterIban*', $pain008.Document.CstmrDrctDbtInitn.PmtInf.CdtrAcct.Id.IBAN))
$replaces.Add(@('*CredaterBic*', $pain008.Document.CstmrDrctDbtInitn.PmtInf.CdtrAgt.FinInstnId.BIC))

foreach ($replace in $replaces) {
    $pain002 = $pain002.Replace($replace[0], $replace[1])
}

$pain002 | Set-Content "PAIN002-$transactionId.xml"

