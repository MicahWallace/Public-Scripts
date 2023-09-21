function Format-UserDescriptionObject {
    param
    (
      [Object]
      [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
      $InputObject
    )
    process {
          
      $InputObject | 
      ForEach-Object {
        $instance = $_
        $instance | 
        Get-Member -MemberType *Property |
        Select-Object -ExpandProperty Name |
        ForEach-Object {
          [PSCustomObject]@{
            Name  = $_
            Value = $instance.$_
          }
        }
      } 
            
    }
  }