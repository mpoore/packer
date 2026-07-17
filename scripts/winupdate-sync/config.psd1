@{
    # Number of most recent monthly release cycles to keep, per product/arch/kind.
    RetentionCount = 3

    Products = @(
        @{
            Name      = 'win2019'
            Arch      = 'x64'
            CutoffDate = '2024-01-01'
            LcuSearch = 'Cumulative Update for Windows Server 2019 x64'
            SsuSearch = 'Servicing Stack Update for Windows Server 2019'
        }
        @{
            Name      = 'win2022'
            Arch      = 'x64'
            CutoffDate = '2024-01-01'
            LcuSearch = 'Cumulative Update for Windows Server 2022 x64'
            SsuSearch = 'Servicing Stack Update for Windows Server 2022'
        }
        @{
            Name      = 'win2025'
            Arch      = 'x64'
            CutoffDate = '2024-01-01'
            LcuSearch = 'Cumulative Update for Windows Server 2025 x64'
            SsuSearch = 'Servicing Stack Update for Windows Server 2025'
        }
    )
}
