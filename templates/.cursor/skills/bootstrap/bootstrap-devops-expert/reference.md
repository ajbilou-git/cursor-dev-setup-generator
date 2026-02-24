# Bootstrap DevOps Expert — Reference

## Changelog sources (fetch and parse)

| Provider | URL | Focus |
|----------|-----|-------|
| azurerm | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/main/CHANGELOG.md | DEPRECATIONS, REMOVALS, BREAKING CHANGES, BUG FIXES |
| Terraform | https://github.com/hashicorp/terraform/releases | Major/minor, upgrade guides |
| azapi | https://github.com/Azure/terraform-provider-azapi/releases | Version notes |
| grafana | https://github.com/grafana/terraform-provider-grafana/releases | Breaking changes |

## Changelog analysis patterns

- **DEPRECATIONS**: Search bootstrap for deprecated resource/attribute; add to "Changes required"
- **REMOVALS**: e.g. `azurerm_mobile_network*` removed in 4.57 — grep bootstrap for usage
- **BREAKING CHANGES**: Attribute renames, required migrations
- **BUG FIXES**: If bootstrap uses affected resource, note fix version for upgrade

## Common bootstrap resources (grep for changelog cross-check)

azurerm_container_group, azurerm_container_registry, azurerm_key_vault, azurerm_log_analytics_workspace, azurerm_mysql_flexible_server, azurerm_recovery_services_vault, azurerm_automation_account, azurerm_automation_runbook, azurerm_virtual_machine, azurerm_subnet, azurerm_network_security_group, azurerm_application_insights, azurerm_dashboard_grafana, azurerm_backup_policy_vm, azurerm_backup_protected_vm, azurerm_storage_account, azurerm_private_endpoint, azurerm_monitor_action_group, data.azurerm_*

## Release pattern categories (from history)

| Category | Examples from releases |
|----------|------------------------|
| Version bumps | Terraform, azurerm, azapi, grafana, Ubuntu |
| Security | ggshield, attestation/SBOM, vars vs secrets |
| Workflows | matrix for envs, split plan/apply, dedicated export-ghvars |
| Terraform | drift fixes, state mv/rm/import, naming conventions |
| Layers | new modules, env bootstrap, DevLake, Grafana |
| Fixes | runner alerting, jumpbox, DevLake firewall, service endpoints |

## Terraform best practices checklist

- `terraform fmt` applied
- Variable/output/resource descriptions present
- `locals` for repeated expressions
- No hardcoded values; use tfvars/variables
- `required_providers` versions consistent across layers
- Meaningful resource names (e.g. `azurerm_container_group.devlake` not `this`)

## Azure naming conventions (bootstrap)

Pattern: `<ApplicationName>-<Environment>-<ResourceCode>-<FunctionnalName>`

Common codes: `rg`, `snet`, `nsg`, `kv`, `st`, `ct`, `aci`, `acr`, `mysql`, `law`, `appi`, `amgw`, `pep`, `ag`, `aa`, `bvault`.

## CI/CD workflow patterns

- Dedicated workflow for GitHub vars export (950-populate-gh-vars)
- Separate plan/apply workflows (30-plan, 31-apply for root; 40-plan, 41-apply for envs)
- Matrix for environments (dev, prod)
- State tooling: 920-state-rm, 930-state-mv, 940-import
- Pre-commit: terraform_fmt, pre-commit-hooks, ggshield

## Bootstrap layer structure (root)

| Layer | Purpose |
|-------|---------|
| 00_network | VNet, subnets, NSG |
| 01_keyvault | Key Vault |
| 02_root_acr | Container registry |
| 03_appinsight | Application Insights |
| 04_runner_aci | JIT runners (ACI) |
| 05_jumpbox | Bastion/jumpbox |
| 06_grafana | Grafana workspace |
| 07_devlake | DevLake MySQL + containers |
| 08_grafana_dashboards | Grafana dashboards |
| 50_environment_bootstrap | Env init (module) |
| 97_alerting | Alerting |
| 98_backupvault | Backup Vault |
| 99_automation | Azure Automation |
| 99_export_ghvars | GitHub vars export |

## Common improvement areas

1. **Version alignment**: Terraform, azurerm, azapi in versions.tf; check changelog for latest.
2. **Naming**: Apply conventions from docs/conventions.md; refactor if inconsistent.
3. **Workflows**: Use matrix for envs; avoid duplication; use reusable actions.
4. **Security**: Non-sensitive in vars; attestation/SBOM for images; ggshield in pre-commit.
5. **Documentation**: Update changelog, conventions, architecture on structural changes.
6. **Drift**: Use terraform plan regularly; fix automation/Grafana drift patterns.

## Release preparation checklist

- [ ] All PRs merged and tested
- [ ] Changelog updated with PR links
- [ ] Version bumps documented (Terraform, providers)
- [ ] Breaking changes clearly stated
- [ ] Documentation (conventions, architecture) updated if needed

## Technology watch — best practices to propose

| Category | Best practice | Bootstrap application |
|----------|---------------|------------------------|
| Security | OIDC for Azure/GitHub | Workflows use use_oidc |
| Security | Non-sensitive in vars | Move from secrets where possible |
| Security | Attestation/SBOM for images | Runner image (PR #309) |
| Security | ggshield in pre-commit | Already in place |
| IaC | Version pinning | Use exact versions (=x.x.x) |
| IaC | Consistent versions across layers | Audit all versions.tf |
| IaC | Meaningful resource names | Avoid `this`, use descriptive |
| CI/CD | Matrix for envs | Plan/apply workflows |
| CI/CD | Reusable actions | Dedicated export-ghvars |
| Drift | Regular terraform plan | Fix automation/Grafana drift |
| Naming | Single resource code per type | Resolve conventions TODO |
