import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:serik/l10n/app_localization.dart';
import '../providers/theme_provider.dart';
import '../model/tenant_model.dart';
import '../theme/app_theme.dart';
import '../widgets/app_components.dart';

class TenantsPage extends StatelessWidget {
  final List<TenantData> tenants;
  final VoidCallback onAddTenant;

  const TenantsPage({super.key, required this.tenants, required this.onAddTenant});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final locale = Localizations.localeOf(context);
    final isSw = locale.languageCode == 'sw';
    final primary = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;
    final bg = isDark ? AppTheme.darkBackground : Colors.grey[50]!;
    final surface = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final textCol = isDark ? Colors.white : Colors.black87;
    final subCol = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final shadow = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.08);

    final activeTenants = tenants.where((t) => t.status == 'Active').length;
    final totalRent = tenants.fold(0.0, (s, t) => s + t.rentAmount);

    if (tenants.isEmpty) {
      return Scaffold(
        backgroundColor: bg,
        body: Center(
          child: ModernEmptyState(
            icon: Icons.people_outline,
            title: l10n.tr('Hakuna Wapangaji', en: 'No Tenants Yet'),
            subtitle: l10n.tr('Bonyeza + kuongeza mpangaji', en: 'Tap + to add a tenant'),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          // Stats bar
          Container(
            margin: const EdgeInsets.fromLTRB(AppTheme.spacing16, AppTheme.spacing16, AppTheme.spacing16, 0),
            padding: const EdgeInsets.all(AppTheme.spacing18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primary, primary.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statChip(
                  '${tenants.length}',
                  isSw ? 'Jumla' : 'Total',
                  Icons.people_rounded,
                  Colors.white,
                ),
                _vDivider(Colors.white.withValues(alpha: 0.3)),
                _statChip(
                  '$activeTenants',
                  isSw ? 'Wanaokaa' : 'Active',
                  Icons.check_circle_rounded,
                  const Color(0xFF86EFAC),
                ),
                _vDivider(Colors.white.withValues(alpha: 0.3)),
                _statChip(
                  'TZS ${NumberFormat('#,###').format(totalRent)}',
                  isSw ? 'Kodi Jumla' : 'Total Rent',
                  Icons.monetization_on_rounded,
                  const Color(0xFFFCD34D),
                ),
              ],
            ),
          ),
          // Tenant list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(AppTheme.spacing16, AppTheme.spacing16, AppTheme.spacing16, AppTheme.spacing80),
              physics: const BouncingScrollPhysics(),
              itemCount: tenants.length,
              itemBuilder: (ctx, i) => _tenantCard(
                tenants[i],
                i,
                isDark,
                surface,
                textCol,
                subCol,
                primary,
                shadow,
                ctx,
                isSw,
                l10n,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: AppTheme.spacing4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: AppTheme.spacing2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _vDivider([Color? color]) {
    return Container(
      width: 1,
      height: 40,
      color: color ?? Colors.grey.withValues(alpha: 0.3),
    );
  }

  Widget _tenantCard(
    TenantData tenant,
    int index,
    bool isDark,
    Color surface,
    Color textCol,
    Color subCol,
    Color primary,
    Color shadow,
    BuildContext ctx,
    bool isSw,
    AppLocalizations l10n,
  ) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        onTap: () {
          // Show tenant details dialog
          _showTenantDetails(ctx, tenant, isDark, surface, textCol, subCol, primary, isSw, l10n);
        },
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primary, primary.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Center(
                  child: Text(
                    tenant.name.isNotEmpty ? tenant.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tenant.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textCol,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing4),
                    Row(
                      children: [
                        Icon(Icons.home_outlined, size: 14, color: subCol),
                        const SizedBox(width: AppTheme.spacing4),
                        Expanded(
                          child: Text(
                            tenant.houseName,
                            style: TextStyle(fontSize: 12, color: subCol),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacing4),
                    Row(
                      children: [
                        Icon(Icons.phone_outlined, size: 14, color: subCol),
                        const SizedBox(width: AppTheme.spacing4),
                        Text(
                          tenant.phone,
                          style: TextStyle(fontSize: 12, color: subCol),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Status & Rent
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing8,
                      vertical: AppTheme.spacing4,
                    ),
                    decoration: BoxDecoration(
                      color: tenant.status == 'Active'
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Text(
                      tenant.status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: tenant.status == 'Active' ? Colors.green : Colors.orange,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing8),
                  Text(
                    'TZS ${NumberFormat('#,###').format(tenant.rentAmount)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTenantDetails(
    BuildContext ctx,
    TenantData tenant,
    bool isDark,
    Color surface,
    Color textCol,
    Color subCol,
    Color primary,
    bool isSw,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: ctx,
      builder: (context) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primary, primary.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Center(
                child: Text(
                  tenant.name.isNotEmpty ? tenant.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: Text(
                tenant.name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textCol,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow(Icons.home_outlined, isSw ? 'Nyumba' : 'House', tenant.houseName, subCol, textCol),
              const SizedBox(height: AppTheme.spacing12),
              _detailRow(Icons.phone_outlined, isSw ? 'Simu' : 'Phone', tenant.phone, subCol, textCol),
              const SizedBox(height: AppTheme.spacing12),
              if (tenant.startDate != null)
                _detailRow(Icons.calendar_today_outlined, isSw ? 'Tarehe ya Kuanza' : 'Start Date', 
                    DateFormat('dd MMM yyyy').format(tenant.startDate!), subCol, textCol),
              if (tenant.endDate != null)
                _detailRow(Icons.event_outlined, isSw ? 'Tarehe ya Mwisho' : 'End Date', 
                    DateFormat('dd MMM yyyy').format(tenant.endDate!), subCol, textCol),
              const SizedBox(height: AppTheme.spacing12),
              _detailRow(Icons.monetization_on_outlined, isSw ? 'Kodi' : 'Rent', 
                  'TZS ${NumberFormat('#,###').format(tenant.rentAmount)}', subCol, textCol),
              const SizedBox(height: AppTheme.spacing12),
              _detailRow(Icons.info_outline, isSw ? 'Hali' : 'Status', tenant.status, subCol, textCol),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.tr('Funga', en: 'Close')),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, Color subCol, Color textCol) {
    return Row(
      children: [
        Icon(icon, size: 18, color: subCol),
        const SizedBox(width: AppTheme.spacing12),
        Text(
          '$label: ',
          style: TextStyle(fontWeight: FontWeight.w600, color: subCol),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: textCol),
          ),
        ),
      ],
    );
  }
}
