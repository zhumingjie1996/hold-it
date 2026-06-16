import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../viewmodels/store_manager.dart';
import '../../utils/constants.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  int _themeModeValue = 0;
  String _currencyCode = 'auto';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _themeModeValue = prefs.getInt('themeMode') ?? 0;
      _currencyCode = prefs.getString('currencyCode') ?? 'auto';
    });
  }

  Future<void> _saveThemeMode(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', value);
    setState(() => _themeModeValue = value);
  }

  Future<void> _saveCurrency(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currencyCode', code);
    setState(() => _currencyCode = code);
  }

  @override
  Widget build(BuildContext context) {
    final storeManager = context.watch<StoreManager>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: ListView(
        children: [
          if (!storeManager.isLoading && !storeManager.isVip)
            _buildCtaBanner(storeManager),
          if (storeManager.isLoading || storeManager.isVip)
            _buildVipSection(storeManager),
          _buildSection('外观', [
            ListTile(
              leading: const Icon(Icons.palette),
              title: const Text('主题'),
              trailing: DropdownButton<int>(
                value: _themeModeValue,
                underline: const SizedBox(),
                items: ThemeModeOption.values.map((mode) {
                  return DropdownMenuItem(
                    value: mode.value,
                    child: Row(
                      spacing: 8,
                      children: [
                        Icon(mode.icon, size: 18),
                        Text(mode.label),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) _saveThemeMode(v);
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text('货币单位'),
              trailing: DropdownButton<String>(
                value: _currencyCode,
                underline: const SizedBox(),
                items: SupportedCurrency.values.map((c) {
                  return DropdownMenuItem(
                    value: c.code,
                    child: Text(c.displayName),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) _saveCurrency(v);
                },
              ),
            ),
          ]),
          _buildSection('关于', [
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('关于忍一下'),
              onTap: () => _showAboutDialog(context),
            ),
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('评价应用'),
              onTap: () {
                // TODO: Open app store
              },
            ),
          ]),
          _buildSection('支持', [
            ListTile(
              leading: const Icon(Icons.restore),
              title: const Text('恢复购买'),
              trailing: storeManager.restoreState == RestoreState.restoring
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : null,
              onTap: () => storeManager.restorePurchases(),
            ),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('意见反馈'),
              onTap: () {
                // TODO: Open email
              },
            ),
          ]),
          _buildSection('法律', [
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('隐私政策'),
              onTap: () => _showLegalDialog(context, '隐私政策', _privacyPolicy),
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('用户协议'),
              onTap: () => _showLegalDialog(context, '用户协议', _termsOfService),
            ),
          ]),
          _buildSection('危险操作', [
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('抹除所有数据', style: TextStyle(color: Colors.red)),
              onTap: () => _showClearDataDialog(context),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildCtaBanner(StoreManager storeManager) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.brand, AppColors.brandDark],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => storeManager.purchase(),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              spacing: 4,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 6,
                  children: [
                    const Icon(Icons.star, color: Colors.yellow, size: 18),
                    const Text(
                      '解锁终身会员',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
                Text(
                  '一次购买，终身使用',
                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVipSection(StoreManager storeManager) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: storeManager.isLoading
          ? Row(
              spacing: 16,
              children: [
                const SizedBox(width: 24, height: 24, child: CircularProgressIndicator()),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    const Text('正在加载会员信息…', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('请稍候', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ],
            )
          : Row(
              spacing: 16,
              children: [
                const Text('👑', style: TextStyle(fontSize: 40)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 6,
                  children: [
                    const Text('已激活终身会员', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('享受所有高级功能', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ),
        Container(
          color: Colors.white,
          child: Column(children: children),
        ),
      ],
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('关于忍一下'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            Text('🫰', style: TextStyle(fontSize: 48)),
            Text('忍一下', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text('记录克制，成就更好的自己'),
            Text('版本 1.1', style: TextStyle(color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showLegalDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(content)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('抹除所有数据'),
        content: const Text('此操作不可恢复，所有忍住记录和自定义分类将被永久删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              context.read<StoreManager>();
              // TODO: Clear all data
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('抹除'),
          ),
        ],
      ),
    );
  }

  static const String _privacyPolicy = '''隐私政策
更新日期：2025 年 6 月 4 日

1. 概述
「忍一下」高度重视您的隐私。本政策说明我们如何处理您在使用本应用时所涉及的信息。

2. 数据收集
本应用完全离线运行，不会收集、上传或共享您的任何个人数据。所有忍住记录、自定义分类、奖励设置及偏好设置均存储在您的设备本地。

3. 数据使用
您的记录数据仅用于在应用内展示统计信息和奖励进度，不会用于任何其他目的。

4. 第三方服务
本应用不使用任何第三方分析工具、广告服务或数据上传服务。

5. 数据安全
您的数据存储在设备本地，受系统级安全机制保护。

6. 联系我们
如您对本隐私政策有任何疑问，请发送邮件至 zhumingjie0822@gmail.com 联系我们。'''

  static const String _termsOfService = '''用户协议
更新日期：2025 年 6 月 4 日

1. 接受条款
使用「忍一下」即表示您已阅读并同意本协议的所有条款。

2. 服务内容
本应用提供忍住行为记录、自定义分类、奖励系统、多维统计等功能。

3. 会员服务
终身会员为一次性购买，购买后即可永久使用所有高级功能。

4. 退款政策
根据应用商店购买政策，退款请通过对应商店申请。

5. 免责声明
本应用按"现状"提供，不附带任何明示或暗示的保证。

6. 联系我们
如您对本协议有任何疑问，请发送邮件至 zhumingjie0822@gmail.com 联系我们。'''
}
