import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

// ═══════════════════════════════════════════════════════════
//  FIRESTORE LIST VIEW — Reusable StreamBuilder + ListView
//
//  SINKRONISASI 3: Global StreamBuilder Template
//  Wraps the 3-state pattern (loading → error → data) into one widget.
//  Used by:
//   - User pages  (fleet list, route list, my bookings)
//   - Admin pages (manifest, trip list)
//   - Super Admin (transaction report, user list)
//
//  Usage:
//    FirestoreListView<BookingModel>(
//      stream: BookingService.userBookingsStream(uid),
//      fromSnapshot: BookingModel.fromFirestore,
//      emptyIcon: Iconsax.receipt_item,
//      emptyTitle: 'Belum ada booking',
//      itemBuilder: (context, booking, index) => BookingCard(booking),
//    )
// ═══════════════════════════════════════════════════════════
class FirestoreListView<T> extends StatelessWidget {
  /// Firestore query snapshot stream.
  final Stream<QuerySnapshot> stream;

  /// Function to convert a DocumentSnapshot → T.
  final T Function(DocumentSnapshot doc) fromSnapshot;

  /// Builds a widget for each item.
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  /// Optional header widget above the list.
  final Widget Function(BuildContext context, List<T> items)? headerBuilder;

  /// Icon, title, subtitle for empty state.
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;

  /// List padding.
  final EdgeInsets padding;

  /// Primary color for loading spinner & empty state.
  final Color primaryColor;

  const FirestoreListView({
    super.key,
    required this.stream,
    required this.fromSnapshot,
    required this.itemBuilder,
    this.headerBuilder,
    this.emptyIcon = Iconsax.document,
    this.emptyTitle = 'Belum Ada Data',
    this.emptySubtitle = 'Data akan muncul di sini secara real-time.',
    this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 32),
    this.primaryColor = const Color(0xFF0F4C81),
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        // ── State 1: Loading ──
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: primaryColor),
          );
        }

        // ── State 2: Error ──
        if (snapshot.hasError) {
          return _EmptyState(
            icon: Iconsax.warning_2,
            title: 'Terjadi Kesalahan',
            subtitle: '${snapshot.error}',
            color: const Color(0xFFDC2626),
          );
        }

        // ── State 3: Empty ──
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return _EmptyState(
            icon: emptyIcon,
            title: emptyTitle,
            subtitle: emptySubtitle,
            color: primaryColor,
          );
        }

        // ── State 4: Data available — parse into typed list ──
        final items = docs.map((d) => fromSnapshot(d)).toList();

        // If a header builder is provided, wrap in Column
        if (headerBuilder != null) {
          return Column(
            children: [
              headerBuilder!(context, items),
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: padding,
                  itemCount: items.length,
                  itemBuilder: (ctx, i) => itemBuilder(ctx, items[i], i),
                ),
              ),
            ],
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: padding,
          itemCount: items.length,
          itemBuilder: (ctx, i) => itemBuilder(ctx, items[i], i),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  SINGLE DOCUMENT STREAM — Real-time single doc listener
//  Used by: e-ticket page to watch booking status changes
// ═══════════════════════════════════════════════════════════
class FirestoreDocBuilder<T> extends StatelessWidget {
  /// Stream of a single document snapshot.
  final Stream<DocumentSnapshot> stream;

  /// Convert doc → T. Returns null if doc doesn't exist.
  final T? Function(DocumentSnapshot doc) fromSnapshot;

  /// Builder when data is available.
  final Widget Function(BuildContext context, T data) builder;

  /// Widget shown while loading.
  final Widget? loadingWidget;

  /// Widget shown if doc is null/missing.
  final Widget? emptyWidget;

  /// Primary color for loading indicator.
  final Color primaryColor;

  const FirestoreDocBuilder({
    super.key,
    required this.stream,
    required this.fromSnapshot,
    required this.builder,
    this.loadingWidget,
    this.emptyWidget,
    this.primaryColor = const Color(0xFF0F4C81),
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        // ── Loading ──
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingWidget ??
              Center(
                child: CircularProgressIndicator(color: primaryColor),
              );
        }

        // ── Error ──
        if (snapshot.hasError) {
          return _EmptyState(
            icon: Iconsax.warning_2,
            title: 'Error',
            subtitle: '${snapshot.error}',
            color: const Color(0xFFDC2626),
          );
        }

        // ── Parse ──
        final doc = snapshot.data;
        if (doc == null || !doc.exists) {
          return emptyWidget ??
              const _EmptyState(
                icon: Iconsax.document,
                title: 'Tidak Ditemukan',
                subtitle: 'Dokumen tidak tersedia.',
                color: Color(0xFF0F4C81),
              );
        }

        final data = fromSnapshot(doc);
        if (data == null) {
          return emptyWidget ??
              const _EmptyState(
                icon: Iconsax.document,
                title: 'Tidak Ditemukan',
                subtitle: 'Data tidak valid.',
                color: Color(0xFF0F4C81),
              );
        }

        return builder(context, data);
      },
    );
  }
}

// ── Shared empty state ──
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: color.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF475569),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
