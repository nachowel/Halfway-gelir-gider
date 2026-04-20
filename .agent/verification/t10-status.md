# T10 Durum Notu

## Durum etiketi
T10 gelir kaydi create/edit/delete repository akisi ve income entry form entegrasyonu tamamlandi

## Kapanis
T10 buyuk olcude kabul edilebilir.

Kanitlanan kapsam daha dardir:
- `source_platform` alaninin create/update akisinda dogru persist edilmesi dogrulandi.
- Income entry formu create yolunda repository'ye dogru draft gonderiyor.
- `transactionId` ile edit submit yolu `updateTransaction` cagriliyor; create yerine update'e gidildigi dogrulandi.

Bu asamada dogrudan kanitlanmayan sey:
- Settlement kaydinin rapora dogru yansimasi T10 kapsaminda dogrudan kanitlanmis degil.

## Edit mode
`EntryScreen`, `transactionId` verilince edit moduna geciyor ve submit sirasinda `updateTransaction(id: widget.transactionId!, draft: draft)` cagiriyor.

Kanit:
- `transactionId` parametresi ve `_isEditing` kapisi: `lib/features/entry/presentation/entry_screen.dart:28`, `lib/features/entry/presentation/entry_screen.dart:72`
- Edit submit yolunda update cagrisi: `lib/features/entry/presentation/entry_screen.dart:328`
- Widget testi create yerine update cagrildigini dogruluyor: `test/features/entry/entry_screen_test.dart:170`

Acik eksik:
- Mevcut transaction degerlerinin forma preload edilmesi icin herhangi bir fetch/hydration akisi gorunmuyor.
- `initState` sadece varsayilan degerler atiyor; mevcut kaydi yukleyen bir okuma yok: `lib/features/entry/presentation/entry_screen.dart:111`

## Settlement
Repository testleri settlement gelirinde `source_platform` alaninin dogru yazildigini dogruluyor.

Kanit:
- Create akisinda `source_platform = uber`: `test/data/app_repository_test.dart:296`
- Update akisinda `source_platform = just_eat`: `test/data/app_repository_test.dart:342`

## Sunday snap
Mevcut davranis: settlement platformu secilince tarih ilgili haftanin Pazar gunune snap ediliyor.

Kanit:
- UI mantigi: `lib/features/entry/presentation/entry_screen.dart:366`
- Widget testi ilk snap davranisini dogruluyor: `test/features/entry/entry_screen_test.dart:122`

Ileri test notu:
- Kullanici tarihi elle degistirdikten sonra source platform degisiminde tarihin tekrar override edilmemesi icin ek regression testi yazilabilir.
