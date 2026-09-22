import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gift_ledger/models/gift.dart';
import 'package:gift_ledger/models/guest.dart';
import 'package:gift_ledger/services/statistics_computation_service.dart';

void main() {
  const service = StatisticsComputationService();

  group('StatisticsComputationService.buildSnapshot', () {
    test('空数据返回默认洞察', () {
      final snapshot = service.buildSnapshot(
        gifts: [],
        guests: [],
        selectedYear: null,
      );

      expect(snapshot.allGifts, isEmpty);
      expect(snapshot.guestMap, isEmpty);
      expect(snapshot.availableYears, isEmpty);
      expect(snapshot.selectedYear, isNull);
      expect(snapshot.yearFilteredGifts, isEmpty);
      expect(snapshot.insights, hasLength(1));
      expect(snapshot.insights.first.title, '开始记录');
    });

    test('正确构建 guestMap', () {
      final guests = [
        Guest(id: 1, name: '张三', relationship: '朋友'),
        Guest(id: 2, name: '李四', relationship: '同事'),
      ];
      final snapshot = service.buildSnapshot(
        gifts: [],
        guests: guests,
        selectedYear: null,
      );

      expect(snapshot.guestMap[1]!.name, '张三');
      expect(snapshot.guestMap[2]!.name, '李四');
    });

    test('availableYears 降序排列', () {
      final gifts = [
        Gift(id: 1, guestId: 1, amount: 100, isReceived: true, eventType: '婚礼', date: DateTime(2023, 1, 1)),
        Gift(id: 2, guestId: 1, amount: 200, isReceived: true, eventType: '婚礼', date: DateTime(2025, 1, 1)),
        Gift(id: 3, guestId: 1, amount: 300, isReceived: true, eventType: '婚礼', date: DateTime(2024, 1, 1)),
      ];
      final snapshot = service.buildSnapshot(
        gifts: gifts,
        guests: [],
        selectedYear: null,
      );

      expect(snapshot.availableYears, [2025, 2024, 2023]);
    });

    test('selectedYear 过滤生效', () {
      final gifts = [
        Gift(id: 1, guestId: 1, amount: 100, isReceived: true, eventType: '婚礼', date: DateTime(2023, 6, 1)),
        Gift(id: 2, guestId: 1, amount: 200, isReceived: true, eventType: '婚礼', date: DateTime(2024, 6, 1)),
      ];
      final snapshot = service.buildSnapshot(
        gifts: gifts,
        guests: [],
        selectedYear: 2023,
      );

      expect(snapshot.selectedYear, 2023);
      expect(snapshot.yearFilteredGifts, hasLength(1));
      expect(snapshot.yearFilteredGifts.first.amount, 100);
    });

    test('不存在的 selectedYear 回退为 null', () {
      final gifts = [
        Gift(id: 1, guestId: 1, amount: 100, isReceived: true, eventType: '婚礼', date: DateTime(2023, 6, 1)),
      ];
      final snapshot = service.buildSnapshot(
        gifts: gifts,
        guests: [],
        selectedYear: 2099,
      );

      expect(snapshot.selectedYear, isNull);
      expect(snapshot.yearFilteredGifts, hasLength(1));
    });
  });

  group('StatisticsInsight.icon', () {
    test('icon 字段返回正确 IconData', () {
      const insight = StatisticsInsight(
        title: '测试',
        value: '100',
        description: '描述',
        icon: Icons.auto_awesome,
      );

      expect(insight.icon, isA<IconData>());
      expect(insight.icon, Icons.auto_awesome);
    });

    test('icon 字段保留 MaterialIcons 字体族', () {
      const insight = StatisticsInsight(
        title: '测试',
        value: '100',
        description: '描述',
        icon: Icons.auto_awesome,
      );

      expect(insight.icon.fontFamily, 'MaterialIcons');
    });
  });

  group('StatisticsComputationService.buildPersonGraph', () {
    test('空数据返回空列表', () {
      final result = service.buildPersonGraph(
        gifts: [],
        guestMap: const {},
      );
      expect(result, isEmpty);
    });

    test('单人多笔正确聚合', () {
      final guests = [Guest(id: 1, name: '张三', relationship: '朋友')];
      final gifts = [
        Gift(id: 1, guestId: 1, amount: 100, isReceived: true, eventType: '婚礼', date: DateTime(2024, 1, 1)),
        Gift(id: 2, guestId: 1, amount: 200, isReceived: false, eventType: '婚礼', date: DateTime(2024, 2, 1)),
        Gift(id: 3, guestId: 1, amount: 50, isReceived: true, eventType: '婚礼', date: DateTime(2024, 3, 1)),
      ];
      final result = service.buildPersonGraph(gifts: gifts, guestMap: {1: guests.first});
      expect(result, hasLength(1));
      final person = result.first;
      expect(person.name, '张三');
      expect(person.totalReceived, 150);
      expect(person.totalSent, 200);
      expect(person.count, 3);
      expect(person.latestDate, DateTime(2024, 3, 1));
    });

    test('未知联系人不空解引用', () {
      final gifts = [
        Gift(id: 1, guestId: 99, amount: 100, isReceived: true, eventType: '婚礼', date: DateTime(2024, 1, 1)),
      ];
      final result = service.buildPersonGraph(gifts: gifts, guestMap: const {});
      expect(result, hasLength(1));
      expect(result.first.name, '未知客人');
      expect(result.first.relationship, '其他');
    });

    test('按总额倒序排列', () {
      final guests = [
        Guest(id: 1, name: '张三', relationship: '朋友'),
        Guest(id: 2, name: '李四', relationship: '同事'),
        Guest(id: 3, name: '王五', relationship: '亲戚'),
      ];
      final guestMap = {for (final g in guests) g.id!: g};
      final gifts = [
        Gift(id: 1, guestId: 1, amount: 100, isReceived: true, eventType: '婚礼', date: DateTime(2024, 1, 1)),
        Gift(id: 2, guestId: 2, amount: 500, isReceived: true, eventType: '婚礼', date: DateTime(2024, 1, 1)),
        Gift(id: 3, guestId: 3, amount: 300, isReceived: true, eventType: '婚礼', date: DateTime(2024, 1, 1)),
      ];
      final result = service.buildPersonGraph(gifts: gifts, guestMap: guestMap);
      expect(result.map((p) => p.name), ['李四', '王五', '张三']);
    });

    test('超过 maxNodes 只保留 Top N', () {
      final guests = List.generate(
        15,
        (i) => Guest(id: i + 1, name: '人${i + 1}', relationship: '朋友'),
      );
      final guestMap = {for (final g in guests) g.id!: g};
      final gifts = guests
          .map((g) => Gift(
                id: g.id,
                guestId: g.id,
                amount: (g.id * 10).toDouble(),
                isReceived: true,
                eventType: '婚礼',
                date: DateTime(2024, 1, 1),
              ))
          .toList();
      final result = service.buildPersonGraph(gifts: gifts, guestMap: guestMap, maxNodes: 5);
      expect(result, hasLength(5));
      // 金额最高的 5 人：人15(150) 人14(140) 人13(130) 人12(120) 人11(110)
      expect(result.first.name, '人15');
      expect(result.last.name, '人11');
    });

    test('收送混合净流入正确', () {
      final guests = [Guest(id: 1, name: '张三', relationship: '朋友')];
      final gifts = [
        Gift(id: 1, guestId: 1, amount: 1000, isReceived: true, eventType: '婚礼', date: DateTime(2024, 1, 1)),
        Gift(id: 2, guestId: 1, amount: 300, isReceived: false, eventType: '婚礼', date: DateTime(2024, 2, 1)),
      ];
      final result = service.buildPersonGraph(gifts: gifts, guestMap: {1: guests.first});
      expect(result.first.netFlow, 700);
    });
  });
}
