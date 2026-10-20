import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../design/hz.dart';
import '../models/models.dart';
import '../state/bank_controller.dart';
import '../widgets/common.dart';
import 'transaction_screen.dart';

/// Search every transaction by name, note, reference or category.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.category});

  final TxCategory? category;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _query = '';
  late TxCategory? _category = widget.category;

  bool _matches(BankTransaction t) {
    if (_category != null && t.category != _category) return false;
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return t.title.toLowerCase().contains(q) ||
        (t.note?.toLowerCase().contains(q) ?? false) ||
        (t.reference?.toLowerCase().contains(q) ?? false) ||
        t.category.label.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final bank = context.watch<BankController>();
    final results = bank.feed.where(_matches).toList();
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          key: const Key('searchField'),
          autofocus: widget.category == null,
          decoration: const InputDecoration(
            hintText: 'Search payments',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
          ),
          onChanged: (v) => setState(() => _query = v.trim()),
        ),
      ),
      body: ResponsiveBody(
        child: Column(
          children: [
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final c in TxCategory.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        avatar: Icon(
                          HzIcons.category(c),
                          size: 16,
                          color: context.hz.category(c),
                        ),
                        label: Text(c.label),
                        selected: _category == c,
                        onSelected: (s) =>
                            setState(() => _category = s ? c : null),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: results.isEmpty
                  ? const Center(child: Text('No payments found'))
                  : SingleChildScrollView(
                      child: TransactionFeed(
                        transactions: results,
                        now: bank.now,
                        onTap: (t) => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TransactionScreen(txId: t.id),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
