#===========================================================================
# Tests - Search and Filter Helpers
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

    if (-not ("Windows.Visibility" -as [type])) {
        Add-Type @"
namespace Windows
{
    public enum Visibility
    {
        Visible,
        Collapsed
    }
}
"@
    }

    if (-not ("System.Windows.Controls.CheckBox" -as [type])) {
        Add-Type @"
namespace System.Windows.Controls
{
    public class CheckBox
    {
        public bool? IsChecked { get; set; }
    }

    public class Label
    {
        public object Content { get; set; }
    }

    public class WrapPanel
    {
        public object Visibility { get; set; }
    }

    public class StackPanel
    {
        public System.Collections.ArrayList Children { get; private set; }

        public StackPanel()
        {
            Children = new System.Collections.ArrayList();
        }
    }
}
"@
    }

    if (-not ("Windows.Controls.Border" -as [type])) {
        Add-Type @"
namespace Windows.Controls
{
    public class Border
    {
        public object Child { get; set; }
        public object Visibility { get; set; }
    }

    public class DockPanel
    {
        public System.Collections.ArrayList Children { get; private set; }
        public object Visibility { get; set; }

        public DockPanel()
        {
            Children = new System.Collections.ArrayList();
        }
    }

    public class StackPanel
    {
        public System.Collections.ArrayList Children { get; private set; }
        public object Visibility { get; set; }

        public StackPanel()
        {
            Children = new System.Collections.ArrayList();
        }
    }

    public class ItemsControl
    {
        public System.Collections.ArrayList Items { get; private set; }
        public object Visibility { get; set; }

        public ItemsControl()
        {
            Items = new System.Collections.ArrayList();
        }
    }

    public class Label
    {
        public object Content { get; set; }
        public object ToolTip { get; set; }
        public object Visibility { get; set; }
    }

    public class CheckBox
    {
        public object Content { get; set; }
        public object ToolTip { get; set; }
        public object Visibility { get; set; }
    }
}
"@
    }

    . (Join-Path $script:repoRoot "functions\private\Find-AppsByNameOrDescription.ps1")
    . (Join-Path $script:repoRoot "functions\private\Find-TweaksByNameOrDescription.ps1")

    function script:New-NoteSearchCollection {
        return ,[System.Collections.ArrayList]::new()
    }

    function script:New-NoteAppSearchItem {
        param([string]$Tag)

        [pscustomobject]@{
            Tag = $Tag
            Visibility = [Windows.Visibility]::Visible
        }
    }

    function script:New-NoteAppCategory {
        param(
            [string]$Label,
            [object[]]$Items
        )

        $labelControl = [pscustomobject]@{
            Content = $Label
            Visibility = [Windows.Visibility]::Visible
        }
        $wrapPanel = [pscustomobject]@{
            Children = New-NoteSearchCollection
            Visibility = [Windows.Visibility]::Visible
        }

        foreach ($item in $Items) {
            $null = $wrapPanel.Children.Add($item)
        }

        $children = New-NoteSearchCollection
        $null = $children.Add($labelControl)
        $null = $children.Add($wrapPanel)

        [pscustomobject]@{
            Children = $children
            Visibility = [Windows.Visibility]::Visible
        }
    }

    function script:New-NoteAppSearchContext {
        param([object[]]$Categories)

        $items = New-NoteSearchCollection
        foreach ($category in $Categories) {
            $null = $items.Add($category)
        }

        $script:sync = [Hashtable]::Synchronized(@{
            ItemsControl = [pscustomobject]@{
                Items = $items
            }
            configs = @{
                applicationsHashtable = @{
                    WPFInstallBrowser = [pscustomobject]@{
                        Content = "Firefox"
                        Description = "Fast private browser"
                        Category = "Browsers"
                    }
                    WPFInstallMedia = [pscustomobject]@{
                        Content = "VLC"
                        Description = "Media player"
                        Category = "Multimedia Tools"
                    }
                    WPFInstallLiteral = [pscustomobject]@{
                        Content = "Tool [abc]"
                        Description = "Literal wildcard sample"
                        Category = "Utilities"
                    }
                    WPFInstallEditor = [pscustomobject]@{
                        Content = "Code Editor"
                        Description = "Text editing"
                        Category = "Development"
                    }
                    WPFInstallPowerToys = [pscustomobject]@{
                        Content = "PowerToys"
                        Description = "A collection of system utilities"
                        Category = "Microsoft Tools"
                    }
                }
            }
        })
        $global:sync = $script:sync
    }

    function script:New-NoteFakeSearchForm {
        param(
            $TweaksPanel,
            $AppxPanel
        )

        $form = [pscustomobject]@{
            tweakspanel = $TweaksPanel
            appxpanel = $AppxPanel
        }
        $form | Add-Member -MemberType ScriptMethod -Name FindName -Value {
            param($name)

            return $this.$name
        }

        $form
    }

    function script:New-NoteTweakLabelItem {
        param(
            [string]$Content,
            [string]$ToolTip = ""
        )

        $item = [Windows.Controls.DockPanel]::new()
        $checkbox = [Windows.Controls.CheckBox]::new()
        $label = [Windows.Controls.Label]::new()
        $label.Content = $Content
        $label.ToolTip = $ToolTip
        $null = $item.Children.Add($checkbox)
        $null = $item.Children.Add($label)
        $item.Visibility = [Windows.Visibility]::Visible
        $item
    }

    function script:New-NoteTweakCheckboxItem {
        param(
            [string]$Content,
            [string]$ToolTip = ""
        )

        $item = [Windows.Controls.StackPanel]::new()
        $checkbox = [Windows.Controls.CheckBox]::new()
        $checkbox.Content = $Content
        $checkbox.ToolTip = $ToolTip
        $null = $item.Children.Add($checkbox)
        $item.Visibility = [Windows.Visibility]::Visible
        $item
    }

    function script:New-NoteTweakCategory {
        param(
            [string]$Label,
            [object[]]$Items
        )

        $categoryLabel = [Windows.Controls.Label]::new()
        $categoryLabel.Content = $Label
        $categoryLabel.Visibility = [Windows.Visibility]::Visible

        $itemsControl = [Windows.Controls.ItemsControl]::new()
        $null = $itemsControl.Items.Add($categoryLabel)
        foreach ($item in $Items) {
            $null = $itemsControl.Items.Add($item)
        }

        $dockPanel = [Windows.Controls.DockPanel]::new()
        $null = $dockPanel.Children.Add($itemsControl)

        $border = [Windows.Controls.Border]::new()
        $border.Child = $dockPanel
        $border.Visibility = [Windows.Visibility]::Visible

        [pscustomobject]@{
            Border = $border
            Label = $categoryLabel
            ItemsControl = $itemsControl
        }
    }

    function script:New-NoteTweakPanel {
        param([object[]]$Categories)

        $panel = [pscustomobject]@{
            Children = New-NoteSearchCollection
        }

        foreach ($category in $Categories) {
            $null = $panel.Children.Add($category.Border)
        }

        $panel
    }

    function script:New-NoteTweakSearchContext {
        param(
            $TweaksPanel,
            $AppxPanel = $null,
            [string]$CurrentTab = "Tweaks"
        )

        $script:sync = [Hashtable]::Synchronized(@{
            currentTab = $CurrentTab
            Form = New-NoteFakeSearchForm -TweaksPanel $TweaksPanel -AppxPanel $AppxPanel
        })
        $global:sync = $script:sync
    }

    function script:Remove-NoteSearchGlobals {
        Remove-Variable -Name sync -Scope Global -ErrorAction SilentlyContinue
    }
}

Describe "Find-AppsByNameOrDescription" {
    AfterEach {
        Remove-NoteSearchGlobals
    }

    It "restores app visibility and respects collapsed category state for empty search" {
        $browserItem = New-NoteAppSearchItem -Tag "WPFInstallBrowser"
        $mediaItem = New-NoteAppSearchItem -Tag "WPFInstallMedia"
        $browserItem.Visibility = [Windows.Visibility]::Collapsed
        $mediaItem.Visibility = [Windows.Visibility]::Collapsed

        $collapsedCategory = New-NoteAppCategory -Label "+ Browsers" -Items @($browserItem)
        $expandedCategory = New-NoteAppCategory -Label "- Media" -Items @($mediaItem)
        $collapsedCategory.Children[1].Visibility = [Windows.Visibility]::Collapsed
        $expandedCategory.Children[1].Visibility = [Windows.Visibility]::Collapsed
        New-NoteAppSearchContext -Categories @($collapsedCategory, $expandedCategory)

        Find-AppsByNameOrDescription -SearchString ""

        $collapsedCategory.Visibility | Should -Be ([Windows.Visibility]::Visible)
        $collapsedCategory.Children[0].Visibility | Should -Be ([Windows.Visibility]::Visible)
        $collapsedCategory.Children[1].Visibility | Should -Be ([Windows.Visibility]::Collapsed)
        $browserItem.Visibility | Should -Be ([Windows.Visibility]::Visible)
        $expandedCategory.Children[1].Visibility | Should -Be ([Windows.Visibility]::Visible)
        $mediaItem.Visibility | Should -Be ([Windows.Visibility]::Visible)
    }

    It "shows matching apps by description and hides categories without matches" {
        $browserItem = New-NoteAppSearchItem -Tag "WPFInstallBrowser"
        $mediaItem = New-NoteAppSearchItem -Tag "WPFInstallMedia"
        $editorItem = New-NoteAppSearchItem -Tag "WPFInstallEditor"
        $browserCategory = New-NoteAppCategory -Label "+ Browsers" -Items @($browserItem, $mediaItem)
        $editorCategory = New-NoteAppCategory -Label "- Editors" -Items @($editorItem)
        New-NoteAppSearchContext -Categories @($browserCategory, $editorCategory)

        Find-AppsByNameOrDescription -SearchString "private"

        $browserCategory.Visibility | Should -Be ([Windows.Visibility]::Visible)
        $browserCategory.Children[0].Content | Should -Be "- Browsers"
        $browserCategory.Children[1].Visibility | Should -Be ([Windows.Visibility]::Visible)
        $browserItem.Visibility | Should -Be ([Windows.Visibility]::Visible)
        $mediaItem.Visibility | Should -Be ([Windows.Visibility]::Collapsed)
        $editorCategory.Visibility | Should -Be ([Windows.Visibility]::Collapsed)
        $editorItem.Visibility | Should -Be ([Windows.Visibility]::Collapsed)
    }

    It "treats wildcard characters as literal app search text" {
        $literalItem = New-NoteAppSearchItem -Tag "WPFInstallLiteral"
        $mediaItem = New-NoteAppSearchItem -Tag "WPFInstallMedia"
        $category = New-NoteAppCategory -Label "- Tools" -Items @($literalItem, $mediaItem)
        New-NoteAppSearchContext -Categories @($category)

        Find-AppsByNameOrDescription -SearchString "[abc]"

        $literalItem.Visibility | Should -Be ([Windows.Visibility]::Visible)
        $mediaItem.Visibility | Should -Be ([Windows.Visibility]::Collapsed)
        $category.Visibility | Should -Be ([Windows.Visibility]::Visible)
    }

    It "filters category chips by exact application category" {
        $utilityItem = New-NoteAppSearchItem -Tag "WPFInstallLiteral"
        $powerToysItem = New-NoteAppSearchItem -Tag "WPFInstallPowerToys"
        $category = New-NoteAppCategory -Label "- Tools" -Items @($utilityItem, $powerToysItem)
        New-NoteAppSearchContext -Categories @($category)

        Find-AppsByNameOrDescription -Categories @("Utilities")

        $utilityItem.Visibility | Should -Be ([Windows.Visibility]::Visible)
        $powerToysItem.Visibility | Should -Be ([Windows.Visibility]::Collapsed)
        $category.Visibility | Should -Be ([Windows.Visibility]::Visible)
    }

    It "shows apps from every selected category when several chips are active" {
        $utilityItem = New-NoteAppSearchItem -Tag "WPFInstallLiteral"
        $powerToysItem = New-NoteAppSearchItem -Tag "WPFInstallPowerToys"
        $browserItem = New-NoteAppSearchItem -Tag "WPFInstallBrowser"
        $category = New-NoteAppCategory -Label "- Tools" -Items @($utilityItem, $powerToysItem, $browserItem)
        New-NoteAppSearchContext -Categories @($category)

        Find-AppsByNameOrDescription -Categories @("Utilities", "Microsoft Tools")

        $utilityItem.Visibility | Should -Be ([Windows.Visibility]::Visible)
        $powerToysItem.Visibility | Should -Be ([Windows.Visibility]::Visible)
        $browserItem.Visibility | Should -Be ([Windows.Visibility]::Collapsed)
    }

    It "applies the search text and the category filter together" {
        $powerToysItem = New-NoteAppSearchItem -Tag "WPFInstallPowerToys"
        $literalItem = New-NoteAppSearchItem -Tag "WPFInstallLiteral"
        $category = New-NoteAppCategory -Label "- Tools" -Items @($powerToysItem, $literalItem)
        New-NoteAppSearchContext -Categories @($category)

        Find-AppsByNameOrDescription -SearchString "PowerToys" -Categories @("Microsoft Tools")

        $powerToysItem.Visibility | Should -Be ([Windows.Visibility]::Visible)
        $literalItem.Visibility | Should -Be ([Windows.Visibility]::Collapsed)
    }

    It "hides a category when the search text matches nothing inside the selected categories" {
        $powerToysItem = New-NoteAppSearchItem -Tag "WPFInstallPowerToys"
        $category = New-NoteAppCategory -Label "- Tools" -Items @($powerToysItem)
        New-NoteAppSearchContext -Categories @($category)

        Find-AppsByNameOrDescription -SearchString "Firefox" -Categories @("Microsoft Tools")

        $powerToysItem.Visibility | Should -Be ([Windows.Visibility]::Collapsed)
        $category.Visibility | Should -Be ([Windows.Visibility]::Collapsed)
    }

    It "expands a collapsed category that has matches for the selected filter" {
        $powerToysItem = New-NoteAppSearchItem -Tag "WPFInstallPowerToys"
        $category = New-NoteAppCategory -Label "+ Tools" -Items @($powerToysItem)
        New-NoteAppSearchContext -Categories @($category)

        Find-AppsByNameOrDescription -Categories @("Microsoft Tools")

        $category.Children[0].Content | Should -Be "- Tools"
        $category.Children[1].Visibility | Should -Be ([Windows.Visibility]::Visible)
    }

    It "re-collapses a category it expanded once the filter is cleared" {
        $powerToysItem = New-NoteAppSearchItem -Tag "WPFInstallPowerToys"
        $category = New-NoteAppCategory -Label "+ Tools" -Items @($powerToysItem)
        New-NoteAppSearchContext -Categories @($category)

        Find-AppsByNameOrDescription -Categories @("Microsoft Tools")
        $category.Children[0].Content | Should -Be "- Tools"

        Find-AppsByNameOrDescription -SearchString ""

        $category.Children[0].Content | Should -Be "+ Tools"
        $category.Children[1].Visibility | Should -Be ([Windows.Visibility]::Collapsed)
    }

    It "leaves a category the user had expanded alone when the filter is cleared" {
        $powerToysItem = New-NoteAppSearchItem -Tag "WPFInstallPowerToys"
        $category = New-NoteAppCategory -Label "- Tools" -Items @($powerToysItem)
        New-NoteAppSearchContext -Categories @($category)

        Find-AppsByNameOrDescription -Categories @("Microsoft Tools")
        Find-AppsByNameOrDescription -SearchString ""

        $category.Children[0].Content | Should -Be "- Tools"
        $category.Children[1].Visibility | Should -Be ([Windows.Visibility]::Visible)
    }
}

Describe "Find-TweaksByNameOrDescription" {
    AfterEach {
        Remove-NoteSearchGlobals
    }

    It "restores category labels and tweak item visibility for empty search" {
        $labelItem = New-NoteTweakLabelItem -Content "Disable Telemetry" -ToolTip "Stop tracking"
        $stackItem = New-NoteTweakCheckboxItem -Content "Show Extensions" -ToolTip "File extension display"
        $category = New-NoteTweakCategory -Label "+ Privacy" -Items @($labelItem, $stackItem)
        $labelItem.Visibility = [Windows.Visibility]::Collapsed
        $stackItem.Visibility = [Windows.Visibility]::Collapsed
        $category.Label.Visibility = [Windows.Visibility]::Collapsed
        $category.Border.Visibility = [Windows.Visibility]::Collapsed
        $panel = New-NoteTweakPanel -Categories @($category)
        New-NoteTweakSearchContext -TweaksPanel $panel

        Find-TweaksByNameOrDescription -SearchString ""

        $category.Border.Visibility | Should -Be ([Windows.Visibility]::Visible)
        $category.Label.Visibility | Should -Be ([Windows.Visibility]::Visible)
        $labelItem.Visibility | Should -Be ([Windows.Visibility]::Visible)
        $stackItem.Visibility | Should -Be ([Windows.Visibility]::Visible)
    }

    It "shows tweak matches by label tooltip and checkbox content" {
        $telemetryItem = New-NoteTweakLabelItem -Content "Disable Telemetry" -ToolTip "Stop tracking"
        $extensionsItem = New-NoteTweakCheckboxItem -Content "Show Extensions" -ToolTip "File extension display"
        $nonMatchItem = New-NoteTweakLabelItem -Content "Enable NumLock" -ToolTip "Keyboard setting"
        $category = New-NoteTweakCategory -Label "+ Privacy" -Items @($telemetryItem, $extensionsItem, $nonMatchItem)
        $panel = New-NoteTweakPanel -Categories @($category)
        New-NoteTweakSearchContext -TweaksPanel $panel

        Find-TweaksByNameOrDescription -SearchString "tracking"

        $category.Border.Visibility | Should -Be ([Windows.Visibility]::Visible)
        $category.Label.Visibility | Should -Be ([Windows.Visibility]::Visible)
        $category.Label.Content | Should -Be "- Privacy"
        $telemetryItem.Visibility | Should -Be ([Windows.Visibility]::Visible)
        $extensionsItem.Visibility | Should -Be ([Windows.Visibility]::Collapsed)
        $nonMatchItem.Visibility | Should -Be ([Windows.Visibility]::Collapsed)

        Find-TweaksByNameOrDescription -SearchString "Show Extensions"

        $telemetryItem.Visibility | Should -Be ([Windows.Visibility]::Collapsed)
        $extensionsItem.Visibility | Should -Be ([Windows.Visibility]::Visible)
        $nonMatchItem.Visibility | Should -Be ([Windows.Visibility]::Collapsed)
    }

    It "hides tweak category panels when no items match" {
        $item = New-NoteTweakLabelItem -Content "Disable Telemetry" -ToolTip "Stop tracking"
        $category = New-NoteTweakCategory -Label "- Privacy" -Items @($item)
        $panel = New-NoteTweakPanel -Categories @($category)
        New-NoteTweakSearchContext -TweaksPanel $panel

        Find-TweaksByNameOrDescription -SearchString "not-present"

        $category.Border.Visibility | Should -Be ([Windows.Visibility]::Collapsed)
        $category.Label.Visibility | Should -Be ([Windows.Visibility]::Collapsed)
        $item.Visibility | Should -Be ([Windows.Visibility]::Collapsed)
    }

    It "searches the AppX panel when AppX is the current tab" {
        $tweakItem = New-NoteTweakLabelItem -Content "Disable Telemetry" -ToolTip "Stop tracking"
        $appxItem = New-NoteTweakCheckboxItem -Content "Xbox Overlay" -ToolTip "Gaming overlay package"
        $tweakCategory = New-NoteTweakCategory -Label "- Privacy" -Items @($tweakItem)
        $appxCategory = New-NoteTweakCategory -Label "+ AppX" -Items @($appxItem)
        $tweakPanel = New-NoteTweakPanel -Categories @($tweakCategory)
        $appxPanel = New-NoteTweakPanel -Categories @($appxCategory)
        New-NoteTweakSearchContext -TweaksPanel $tweakPanel -AppxPanel $appxPanel -CurrentTab "AppX"

        Find-TweaksByNameOrDescription -SearchString "overlay"

        $appxCategory.Border.Visibility | Should -Be ([Windows.Visibility]::Visible)
        $appxCategory.Label.Content | Should -Be "- AppX"
        $appxItem.Visibility | Should -Be ([Windows.Visibility]::Visible)
        $tweakCategory.Border.Visibility | Should -Be ([Windows.Visibility]::Visible)
        $tweakItem.Visibility | Should -Be ([Windows.Visibility]::Visible)
    }
}
