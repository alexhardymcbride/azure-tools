################################
# Add DNS Records to Azure DNS
# Supports A, CNAME, MX, TXT
# See this KB for other record types:
# https://docs.microsoft.com/en-us/azure/dns/dns-operations-recordsets
################################


Import-Module Az
Connect-AzAccount

$records = Import-Csv -Path "records.csv"
#CSV should be populated with fields: Name, Type, TTL, Value, Zone, ResourceGroup, Preference (if MX)

foreach ($record in $records) {
    #Check if this record should be added to an existing record set.
    $rs = Get-AzDnsRecordSet -Name $record.Name -RecordType $record.Type -ZoneName $record.Zone -ResourceGroupName $record.ResourceGroup
    if ($rs) {
        #If its an MX record and has a preference set, add it with the preference.
        if ($record.Type -eq "MX" -and $record.Preference) {
            Add-AzDnsRecordConfig -RecordSet $rs -Exchange $record.Value -Preference $record.Preference
            Set-AzDnsRecordSet -RecordSet $rs
        }
        #If its an MX record without a preference.
        elseif ($record.Type -eq "MX") {
            Add-AzDnsRecordConfig -RecordSet $rs -Exchange $record.Value
            Set-AzDnsRecordSet -RecordSet $rs
        }
        #If its a CNAME record.
        elseif ($record.Type -eq "CNAME") {
            Add-AzDnsRecordConfig -RecordSet $rs -Cname $record.Value
            Set-AzDnsRecordSet -RecordSet $rs
        }
        #If its a TXT record.
        elseif ($record.Type -eq "TXT") {
            Add-AzDnsRecordConfig -RecordSet $rs -Value $record.Value
            Set-AzDnsRecordSet -RecordSet $rs
        }
        #Add other records
        else {
            Add-AzDnsRecordConfig -RecordSet $rs -Ipv4Address $record.Value
            Set-AzDnsRecordSet -RecordSet $rs
        }
    }

    #If there isn't already a record set, add a new one.
    else {
        #If its an MX record and has a preference set, add it with the preference.
        if ($record.Type -eq "MX" -and $record.Preference) {
            New-AzDnsRecordSet -Name $record.Name -RecordType $record.Type -ZoneName $record.Zone -ResourceGroupName $record.ResourceGroup -Ttl $record.TTL -DnsRecords (New-AzDnsRecordConfig -Exchange $record.Value -Preference $record.Preference)
        }
        #If its an MX record without a preference set.
        elseif ($record.Type -eq "MX") {
            New-AzDnsRecordSet -Name $record.Name -RecordType $record.Type -ZoneName $record.Zone -ResourceGroupName $record.ResourceGroup -Ttl $record.TTL -DnsRecords (New-AzDnsRecordConfig -Exchange $record.Value)
        }
        #If its a CNAME record.
        elseif ($record.Type -eq "CNAME") {
            New-AzDnsRecordSet -Name $record.Name -RecordType $record.Type -ZoneName $record.Zone -ResourceGroupName $record.ResourceGroup -Ttl $record.TTL -DnsRecords (New-AzDnsRecordConfig -Cname $record.Value)
        }
        #If its a TXT record.
        elseif ($record.Type -eq "TXT") {
            New-AzDnsRecordSet -Name $record.Name -RecordType $record.Type -ZoneName $record.Zone -ResourceGroupName $record.ResourceGroup -Ttl $record.TTL -DnsRecords (New-AzDnsRecordConfig -Value $record.Value)
        }
        #Add other records
        else {
            New-AzDnsRecordSet -Name $record.Name -RecordType $record.Type -ZoneName $record.Zone -ResourceGroupName $record.ResourceGroup -Ttl $record.TTL -DnsRecords (New-AzDnsRecordConfig -Ipv4Address $record.Value)
        }
    }
}
