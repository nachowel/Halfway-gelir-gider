import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final _PostgresTools? tools = _PostgresTools.discover();

  group(
    'suppliers migration',
    skip: tools == null ? 'PostgreSQL binaries not available.' : false,
    () {
      _TempPostgresCluster? cluster;

      setUpAll(() async {
        cluster = await _TempPostgresCluster.start(tools!);
      });

      tearDownAll(() async {
        await cluster?.stop();
      });

      test('clean DB applies supplier FK as nullable with ON DELETE SET NULL', () async {
        const String databaseName = 'mig_clean_suppliers';
        await cluster!.createDatabase(databaseName);
        await cluster!.applyBootstrap(databaseName);
        await cluster!.applyMigrations(
          databaseName,
          const <String>[
            'supabase/migrations/001_initial_schema.sql',
            'supabase/migrations/002_rls_policies.sql',
            'supabase/migrations/003_mark_recurring_paid.sql',
            'supabase/migrations/004_harden_auth_signup_bootstrap.sql',
            'supabase/migrations/005_suppliers.sql',
          ],
        );

        await cluster!.sql(databaseName, '''
insert into auth.users (id, email)
values ('11111111-1111-4111-8111-111111111111', 'owner@example.com');

insert into public.categories (id, user_id, type, name)
values ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', '11111111-1111-4111-8111-111111111111', 'expense', 'Rent');

insert into public.suppliers (id, user_id, expense_category_id, name)
values ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', '11111111-1111-4111-8111-111111111111', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Acme Ltd');

insert into public.transactions (
  id,
  user_id,
  type,
  occurred_on,
  amount_minor,
  category_id,
  payment_method,
  supplier_id,
  vendor
)
values (
  'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
  '11111111-1111-4111-8111-111111111111',
  'expense',
  '2026-04-22',
  5000,
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  'card',
  'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
  'Acme Ltd'
);
''');

        expect(
          await cluster!.scalar(
            databaseName,
            '''
select is_nullable
from information_schema.columns
where table_schema = 'public'
  and table_name = 'transactions'
  and column_name = 'supplier_id';
''',
          ),
          'YES',
        );
        expect(
          await cluster!.scalar(
            databaseName,
            '''
select pg_get_constraintdef(oid)
from pg_constraint
where conname = 'transactions_supplier_id_fkey';
''',
          ),
          contains('ON DELETE SET NULL'),
        );

        await cluster!.sql(
          databaseName,
          "delete from public.suppliers where id = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';",
        );

        expect(
          await cluster!.scalar(
            databaseName,
            '''
select coalesce(supplier_id::text, 'NULL')
from public.transactions
where id = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
''',
          ),
          'NULL',
        );
      });

      test(
        'existing DB upgrades to supplier column without breaking old transactions',
        () async {
          const String databaseName = 'mig_existing_suppliers';
          await cluster!.createDatabase(databaseName);
          await cluster!.applyBootstrap(databaseName);
          await cluster!.applyMigrations(
            databaseName,
            const <String>[
              'supabase/migrations/001_initial_schema.sql',
              'supabase/migrations/002_rls_policies.sql',
              'supabase/migrations/003_mark_recurring_paid.sql',
              'supabase/migrations/004_harden_auth_signup_bootstrap.sql',
            ],
          );

          await cluster!.sql(databaseName, '''
insert into auth.users (id, email)
values ('21111111-1111-4111-8111-111111111111', 'legacy@example.com');

insert into public.categories (id, user_id, type, name)
values ('2aaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', '21111111-1111-4111-8111-111111111111', 'expense', 'Supplies');

insert into public.transactions (
  id,
  user_id,
  type,
  occurred_on,
  amount_minor,
  category_id,
  payment_method,
  vendor
)
values (
  '2ccccccc-cccc-4ccc-8ccc-cccccccccccc',
  '21111111-1111-4111-8111-111111111111',
  'expense',
  '2026-04-20',
  2400,
  '2aaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  'cash',
  'Legacy Vendor'
);
''');

          await cluster!.applyMigrations(
            databaseName,
            const <String>['supabase/migrations/005_suppliers.sql'],
          );

          expect(
            await cluster!.scalar(
              databaseName,
              '''
select is_nullable
from information_schema.columns
where table_schema = 'public'
  and table_name = 'transactions'
  and column_name = 'supplier_id';
''',
            ),
            'YES',
          );
          expect(
            await cluster!.scalar(
              databaseName,
              '''
select coalesce(supplier_id::text, 'NULL')
from public.transactions
where id = '2ccccccc-cccc-4ccc-8ccc-cccccccccccc';
''',
            ),
            'NULL',
          );
          expect(
            await cluster!.scalar(
              databaseName,
              '''
select vendor
from public.transactions
where id = '2ccccccc-cccc-4ccc-8ccc-cccccccccccc';
''',
            ),
            'Legacy Vendor',
          );
        },
      );

      test(
        'supplier constraints reject non-expense mismatches and allow archived-name reuse',
        () async {
          const String databaseName = 'mig_supplier_constraints';
          await cluster!.createDatabase(databaseName);
          await cluster!.applyBootstrap(databaseName);
          await cluster!.applyMigrations(
            databaseName,
            const <String>[
              'supabase/migrations/001_initial_schema.sql',
              'supabase/migrations/002_rls_policies.sql',
              'supabase/migrations/003_mark_recurring_paid.sql',
              'supabase/migrations/004_harden_auth_signup_bootstrap.sql',
              'supabase/migrations/005_suppliers.sql',
            ],
          );

          await cluster!.sql(databaseName, '''
insert into auth.users (id, email)
values
  ('31111111-1111-4111-8111-111111111111', 'owner@example.com'),
  ('32222222-2222-4222-8222-222222222222', 'other@example.com');

insert into public.categories (id, user_id, type, name)
values
  ('3aaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', '31111111-1111-4111-8111-111111111111', 'expense', 'Rent'),
  ('3fffffff-ffff-4fff-8fff-ffffffffffff', '31111111-1111-4111-8111-111111111111', 'expense', 'Supplies'),
  ('3bbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', '31111111-1111-4111-8111-111111111111', 'income', 'Card Sales'),
  ('3ddddddd-dddd-4ddd-8ddd-dddddddddddd', '32222222-2222-4222-8222-222222222222', 'expense', 'Fuel');

insert into public.suppliers (id, user_id, expense_category_id, name)
values ('3ccccccc-cccc-4ccc-8ccc-cccccccccccc', '31111111-1111-4111-8111-111111111111', '3aaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Acme Ltd');

update public.suppliers
set is_archived = true
where id = '3ccccccc-cccc-4ccc-8ccc-cccccccccccc';

insert into public.suppliers (id, user_id, expense_category_id, name)
values ('3eeeeeee-eeee-4eee-8eee-eeeeeeeeeeee', '31111111-1111-4111-8111-111111111111', '3aaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Acme Ltd');

insert into public.suppliers (id, user_id, expense_category_id, name)
values ('39999999-9999-4999-8999-999999999999', '32222222-2222-4222-8222-222222222222', '3ddddddd-dddd-4ddd-8ddd-dddddddddddd', 'Other User Fuel');
''');

          await cluster!.expectFailure(
            databaseName,
            '''
insert into public.suppliers (user_id, expense_category_id, name)
values ('31111111-1111-4111-8111-111111111111', '3bbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'Income Supplier');
''',
            contains('Supplier must reference an expense category'),
          );

          await cluster!.expectFailure(
            databaseName,
            '''
insert into public.suppliers (user_id, expense_category_id, name)
values ('31111111-1111-4111-8111-111111111111', '3ddddddd-dddd-4ddd-8ddd-dddddddddddd', 'Cross User Supplier');
''',
            contains('Category does not belong to the same user as supplier'),
          );

          await cluster!.expectFailure(
            databaseName,
            '''
insert into public.transactions (
  user_id,
  type,
  occurred_on,
  amount_minor,
  category_id,
  payment_method,
  supplier_id
)
values (
  '31111111-1111-4111-8111-111111111111',
  'income',
  '2026-04-22',
  1200,
  '3bbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
  'card',
  '3eeeeeee-eeee-4eee-8eee-eeeeeeeeeeee'
);
''',
            contains('Supplier can only be attached to expense transactions'),
          );

          await cluster!.expectFailure(
            databaseName,
            '''
insert into public.transactions (
  user_id,
  type,
  occurred_on,
  amount_minor,
  category_id,
  payment_method,
  supplier_id
)
values (
  '31111111-1111-4111-8111-111111111111',
  'expense',
  '2026-04-22',
  1200,
  '3aaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  'card',
  '39999999-9999-4999-8999-999999999999'
);
''',
            contains('Supplier does not belong to the same user as transaction'),
          );

          await cluster!.expectFailure(
            databaseName,
            '''
insert into public.transactions (
  user_id,
  type,
  occurred_on,
  amount_minor,
  category_id,
  payment_method,
  supplier_id
)
values (
  '31111111-1111-4111-8111-111111111111',
  'expense',
  '2026-04-22',
  1200,
  '3fffffff-ffff-4fff-8fff-ffffffffffff',
  'card',
  '3eeeeeee-eeee-4eee-8eee-eeeeeeeeeeee'
);
''',
            contains('Supplier category'),
          );

          expect(
            await cluster!.scalar(
              databaseName,
              '''
select count(*)
from public.suppliers
where user_id = '31111111-1111-4111-8111-111111111111'
  and expense_category_id = '3aaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'
  and lower(name) = lower('Acme Ltd');
''',
            ),
            '2',
          );
        },
      );
    },
  );
}

class _PostgresTools {
  const _PostgresTools({
    required this.initdb,
    required this.pgCtl,
    required this.psql,
  });

  final String initdb;
  final String pgCtl;
  final String psql;

  static _PostgresTools? discover() {
    String? resolve(String executable) {
      final String commonWindowsPath =
          'C:\\Program Files\\PostgreSQL\\17\\bin\\$executable.exe';
      if (Platform.isWindows && File(commonWindowsPath).existsSync()) {
        return commonWindowsPath;
      }

      final ProcessResult result = Process.runSync(
        Platform.isWindows ? 'where' : 'which',
        <String>[Platform.isWindows ? '$executable.exe' : executable],
      );
      if (result.exitCode != 0) {
        return null;
      }
      final String output = (result.stdout as String).trim();
      if (output.isEmpty) {
        return null;
      }
      return output.split(RegExp(r'[\r\n]+')).first.trim();
    }

    final String? initdb = resolve('initdb');
    final String? pgCtl = resolve('pg_ctl');
    final String? psql = resolve('psql');
    if (initdb == null || pgCtl == null || psql == null) {
      return null;
    }
    return _PostgresTools(initdb: initdb, pgCtl: pgCtl, psql: psql);
  }
}

class _TempPostgresCluster {
  _TempPostgresCluster._({
    required _PostgresTools tools,
    required Directory rootDir,
    required Directory dataDir,
    required this.port,
  }) : _tools = tools,
       _rootDir = rootDir,
       _dataDir = dataDir;

  final _PostgresTools _tools;
  final Directory _rootDir;
  final Directory _dataDir;
  final int port;

  static Future<_TempPostgresCluster> start(_PostgresTools tools) async {
    final Directory rootDir = await Directory.systemTemp.createTemp(
      'gider-suppliers-migration-',
    );
    final Directory dataDir = Directory(
      '${rootDir.path}${Platform.pathSeparator}data',
    );
    final int port = 55432 + (DateTime.now().millisecondsSinceEpoch % 1000);
    final _TempPostgresCluster cluster = _TempPostgresCluster._(
      tools: tools,
      rootDir: rootDir,
      dataDir: dataDir,
      port: port,
    );

    await cluster._run(
      tools.initdb,
      <String>[
        '-A',
        'trust',
        '-U',
        'postgres',
        '-D',
        dataDir.path,
      ],
    );
    await cluster._run(
      tools.pgCtl,
      <String>[
        '-D',
        dataDir.path,
        '-o',
        '-F -h 127.0.0.1 -p $port',
        '-w',
        'start',
      ],
    );
    return cluster;
  }

  Future<void> stop() async {
    try {
      await _run(
        _tools.pgCtl,
        <String>[
          '-D',
          _dataDir.path,
          '-m',
          'immediate',
          '-w',
          'stop',
        ],
      );
    } finally {
      if (_rootDir.existsSync()) {
        await _rootDir.delete(recursive: true);
      }
    }
  }

  Future<void> createDatabase(String name) {
    return sql('postgres', 'create database $name;');
  }

  Future<void> applyBootstrap(String databaseName) {
    return sql(databaseName, '''
create schema if not exists auth;

create or replace function auth.uid()
returns uuid
language sql
stable
as \$\$
  select null::uuid;
\$\$;

create table if not exists auth.users (
  id uuid primary key,
  email text,
  raw_user_meta_data jsonb not null default '{}'::jsonb
);
''');
  }

  Future<void> applyMigrations(
    String databaseName,
    List<String> relativePaths,
  ) async {
    for (final String relativePath in relativePaths) {
      await _run(
        _tools.psql,
        <String>[
          '-h',
          '127.0.0.1',
          '-p',
          '$port',
          '-U',
          'postgres',
          '-d',
          databaseName,
          '-v',
          'ON_ERROR_STOP=1',
          '-f',
          File(relativePath).absolute.path,
        ],
      );
    }
  }

  Future<void> sql(String databaseName, String sql) async {
    await _run(
      _tools.psql,
      <String>[
        '-h',
        '127.0.0.1',
        '-p',
        '$port',
        '-U',
        'postgres',
        '-d',
        databaseName,
        '-v',
        'ON_ERROR_STOP=1',
        '-c',
        sql,
      ],
    );
  }

  Future<String> scalar(String databaseName, String sql) async {
    final ProcessResult result = await _run(
      _tools.psql,
      <String>[
        '-h',
        '127.0.0.1',
        '-p',
        '$port',
        '-U',
        'postgres',
        '-d',
        databaseName,
        '-v',
        'ON_ERROR_STOP=1',
        '-t',
        '-A',
        '-c',
        sql,
      ],
    );
    return (result.stdout as String).trim();
  }

  Future<void> expectFailure(
    String databaseName,
    String sql,
    Matcher stderrMatcher,
  ) async {
    final ProcessResult result = await Process.run(
      _tools.psql,
      <String>[
        '-h',
        '127.0.0.1',
        '-p',
        '$port',
        '-U',
        'postgres',
        '-d',
        databaseName,
        '-v',
        'ON_ERROR_STOP=1',
        '-c',
        sql,
      ],
    );
    expect(result.exitCode, isNot(0));
    expect('${result.stderr}', stderrMatcher);
  }

  Future<ProcessResult> _run(String command, List<String> arguments) async {
    final ProcessResult result = await Process.run(
      command,
      arguments,
    );
    if (result.exitCode != 0) {
      throw StateError(
        'Command failed: $command ${arguments.join(' ')}\n'
        'stdout:\n${result.stdout}\n'
        'stderr:\n${result.stderr}',
      );
    }
    return result;
  }
}
