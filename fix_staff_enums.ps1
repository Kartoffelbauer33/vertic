# PowerShell Script to fix StaffUserType enum references
# Remove all references to facilityAdmin and hallAdmin

$files = @(
    "vertic_app\vertic\vertic_project\vertic_staff_app\lib\widgets\rbac\staff_user_management_widget.dart",
    "vertic_app\vertic\vertic_project\vertic_staff_app\lib\widgets\rbac\role_assignment_dialog.dart",
    "vertic_app\vertic\vertic_project\vertic_staff_app\lib\main.dart",
    "vertic_app\vertic\vertic_project\vertic_staff_app\lib\auth\staff_auth_provider.dart",
    "vertic_app\vertic\vertic_project\vertic_staff_app\lib\services\rbac\staff_user_management_service.dart",
    "vertic_app\vertic\vertic_project\vertic_staff_app\lib\services\rbac\rbac_helper_service.dart",
    "vertic_app\vertic\vertic_project\vertic_staff_app\lib\pages\admin\staff_user_management_page.dart",
    "vertic_app\vertic\vertic_project\vertic_staff_app\lib\pages\admin\staff_new_page.dart",
    "vertic_app\vertic\vertic_project\vertic_staff_app\lib\pages\admin\staff_management_page.dart",
    "vertic_app\vertic\vertic_project\vertic_staff_app\lib\pages\admin\new_staff_management.dart"
)

foreach ($file in $files) {
    $fullPath = Join-Path $PSScriptRoot $file
    if (Test-Path $fullPath) {
        Write-Host "Processing: $file"
        $content = Get-Content $fullPath -Raw
        
        # Remove case statements for facilityAdmin and hallAdmin
        $content = $content -replace "case StaffUserType\.facilityAdmin:\s*return [^;]+;", ""
        $content = $content -replace "case StaffUserType\.hallAdmin:\s*return [^;]+;", ""
        
        # Remove dropdown items
        $content = $content -replace "DropdownMenuItem[^>]*value:\s*StaffUserType\.facilityAdmin[^,]*,[^)]*\),", ""
        $content = $content -replace "DropdownMenuItem[^>]*value:\s*StaffUserType\.hallAdmin[^,]*,[^)]*\),", ""
        
        # Remove conditions
        $content = $content -replace "\|\|\s*s\.staffLevel == StaffUserType\.facilityAdmin", ""
        $content = $content -replace "\|\|\s*s\.staffLevel == StaffUserType\.hallAdmin", ""
        $content = $content -replace "s\.staffLevel == StaffUserType\.facilityAdmin\s*\|\|", ""
        $content = $content -replace "s\.staffLevel == StaffUserType\.hallAdmin\s*\|\|", ""
        
        Set-Content $fullPath $content
        Write-Host "Fixed: $file" -ForegroundColor Green
    }
}

Write-Host "Done!" -ForegroundColor Cyan