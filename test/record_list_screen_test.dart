import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gift_ledger/models/gift.dart';
import 'package:gift_ledger/models/guest.dart';
import 'package:gift_ledger/screens/record_list_screen.dart';
import 'package:gift_ledger/widgets/records/record_summary_card.dart';

class FakeRecordListStorageService implements RecordListStorage {
  FakeRecordListStorageService({
    required this.gifts,
    required this.guests,
  });

  final List<Gift> gifts;
  final List<Guest> guests;
  final List<VoidCallback> _listeners = [];

  @override
  void addListener(VoidCallback listener) => _listeners.add(listener);

  @override
  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  @override
  Future<List<Gift>> getAllGifts() async => gifts;

  @override
  Future<List<Guest>> getAllGuests() async => guests;

  @override
  Future<int> deleteGift(int id) async => 1;
}

void main() {
  testWidgets('RecordListScreen 会通过真实页面接线展示备注摘要', (WidgetTester tester) async {
    final storage = FakeRecordListStorageService(
      gifts: [
        Gift(
          id: 1,
          guestId: 1,
          amount: 300,
          isReceived: true,
          eventType: EventTypes.wedding,
          date: DateTime(2026, 3, 24),
          note: '全部记录页的备注摘要',
        ),
      ],
      guests: [
        Guest(id: 1, name: '张三', relationship: '朋友'),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: RecordListScreen(storageService: storage),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(find.text('全部记录页的备注摘要'), findsOneWidget);
    expect(find.byType(RecordSummaryCard), findsOneWidget);
  });

  testWidgets('RecordListScreen 收礼筛选下搜索不会混入送礼记录',
      (WidgetTester tester) async {
    final storage = FakeRecordListStorageService(
      gifts: [
        Gift(
          id: 1,
          guestId: 1,
          amount: 300,
          isReceived: true,
          eventType: EventTypes.wedding,
          date: DateTime(2026, 3, 24),
        ),
        Gift(
          id: 2,
          guestId: 2,
          amount: 500,
          isReceived: false,
          eventType: EventTypes.wedding,
          date: DateTime(2026, 3, 25),
        ),
      ],
      guests: [
        Guest(id: 1, name: '张三', relationship: '朋友'),
        Guest(id: 2, name: '张三', relationship: '朋友'),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: RecordListScreen(isReceived: true, storageService: storage),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 笔记录'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, '搜索姓名'),
      '张三',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('1 笔记录'), findsOneWidget);
    expect(find.text('2 笔记录'), findsNothing);
  });
}
