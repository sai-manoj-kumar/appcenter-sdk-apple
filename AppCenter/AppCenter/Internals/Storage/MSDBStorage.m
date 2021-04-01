// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

//#import <sqlite3.h>

#import "MSAppCenterInternal.h"
#import "MSDBStoragePrivate.h"
#import "MSUtility+File.h"

static dispatch_once_t sqliteConfigurationResultOnceToken;
static int sqliteConfigurationResult = 1;

@implementation MSDBStorage

+ (void)load {

  /*
   * Configure SQLite at load time to invoke configuration only once and before opening a DB.
   * If it is custom SQLite library we need to turn on URI filename capability.
   */
  sqliteConfigurationResult = [self configureSQLite];
}

- (instancetype)initWithSchema:(MSDBSchema *)schema version:(NSUInteger)version filename:(NSString *)filename {

  // Log SQLite configuration result only once at init time because log level won't be set at load time.
  dispatch_once(&sqliteConfigurationResultOnceToken, ^{
    if (sqliteConfigurationResult == 0) {
      MSLogDebug([MSAppCenter logTag], @"SQLite global configuration successfully updated.");
    } else {
      NSString *errorString;
    errorString = @(sqliteConfigurationResult).stringValue;
      MSLogError([MSAppCenter logTag], @"Failed to update SQLite global configuration. Error: %@.", errorString);
    }
  });
  if ((self = [super init])) {
    int result = [self configureDatabaseWithSchema:schema version:version filename:filename];
    if (result == 11 || result == 26) {
      [self dropDatabase];
      result = [self configureDatabaseWithSchema:schema version:version filename:filename];
    }
    if (result != 0) {
      MSLogError([MSAppCenter logTag], @"Failed to initialize database.");
    }
  }
  return self;
}

- (instancetype)initWithVersion:(NSUInteger)version filename:(NSString *)filename {
  return (self = [self initWithSchema:nil version:version filename:filename]);
}

- (int)configureDatabaseWithSchema:(MSDBSchema *)schema version:(NSUInteger)version filename:(NSString *)filename {
/*
    BOOL newDatabase = ![MSUtility fileExistsForPathComponent:filename];
  self.dbFileURL = [MSUtility createFileAtPathComponent:filename withData:nil atomically:NO forceOverwrite:NO];
  self.maxSizeInBytes = kMSDefaultDatabaseSizeInBytes;
  int result;
  sqlite3 *db = [MSDBStorage openDatabaseAtFileURL:self.dbFileURL withResult:&result];
  if (result != SQLITE_OK) {
    return result;
  }
  self.pageSize = [MSDBStorage getPageSizeInOpenedDatabase:db];
  NSUInteger databaseVersion = [MSDBStorage versionInOpenedDatabase:db result:&result];
  if (result != SQLITE_OK) {
    sqlite3_close(db);
    return result;
  }

  // Create table.
  if (schema) {
    result = [MSDBStorage createTablesWithSchema:schema inOpenedDatabase:db];
    if (result != SQLITE_OK) {
      MSLogError([MSAppCenter logTag], @"Failed to create tables with schema with error \"%d\".", result);
      sqlite3_close(db);
      return result;
    }
  }
  if (newDatabase) {
    MSLogInfo([MSAppCenter logTag], @"Created \"%@\" database with %lu version.", filename, (unsigned long)version);
    [self customizeDatabase:db];
  } else if (databaseVersion < version) {
    MSLogInfo([MSAppCenter logTag], @"Migrating \"%@\" database from version %lu to %lu.", filename, (unsigned long)databaseVersion,
              (unsigned long)version);
    [self migrateDatabase:db fromVersion:databaseVersion];
  }
  [MSDBStorage enableAutoVacuumInOpenedDatabase:db];
  [MSDBStorage setVersion:version inOpenedDatabase:db];
  sqlite3_close(db);
    */
  return 0;
}

- (int)executeQueryUsingBlock:(MSDBStorageQueryBlock)callback {
    /*
  int result;

  sqlite3 *db = [MSDBStorage openDatabaseAtFileURL:self.dbFileURL withResult:&result];
  if (!db) {
    return result;
  }

  // The value is stored as part of the database connection and must be reset every time the database is opened.
  long maxPageCount = self.maxSizeInBytes / self.pageSize;
  result = [MSDBStorage setMaxPageCount:maxPageCount inOpenedDatabase:db];

  // Do not proceed with the query if the database is corrupted.
  if (result == SQLITE_CORRUPT || result == SQLITE_NOTADB) {
    sqlite3_close(db);
    return result;
  }

  // Log a warning if max page count can't be set.
  if (result != SQLITE_OK) {
    MSLogError([MSAppCenter logTag], @"Failed to open database with specified maximum size constraint.");
  }
  result = callback(db);
  sqlite3_close(db);
  return result;
     */
    return 0;
}

- (BOOL)dropTable:(NSString *)tableName {
    /*
  return [self executeQueryUsingBlock:^int(void *db) {
           if ([MSDBStorage tableExists:tableName inOpenedDatabase:db]) {
             NSString *deleteQuery = [NSString stringWithFormat:@"DROP TABLE \"%@\";", tableName];
             int result = [MSDBStorage executeNonSelectionQuery:deleteQuery inOpenedDatabase:db];
             if (result == SQLITE_OK) {
               MSLogVerbose([MSAppCenter logTag], @"Table %@ has been deleted", tableName);
             } else {
               MSLogError([MSAppCenter logTag], @"Failed to delete table %@", tableName);
             }
             return result;
           }
           return SQLITE_OK;
         }] == SQLITE_OK;
     */
    return 0;
}

- (void)dropDatabase {
  BOOL result = [MSUtility deleteFileAtURL:self.dbFileURL];
  if (result) {
    MSLogVerbose([MSAppCenter logTag], @"Database %@ has been deleted.", (NSString * _Nonnull) self.dbFileURL.absoluteString);
  } else {
    MSLogError([MSAppCenter logTag], @"Failed to delete database.");
  }
}

- (BOOL)createTable:(NSString *)tableName columnsSchema:(MSDBColumnsSchema *)columnsSchema {
  return [self createTable:tableName columnsSchema:columnsSchema uniqueColumnsConstraint:nil];
}

- (BOOL)createTable:(NSString *)tableName
              columnsSchema:(MSDBColumnsSchema *)columnsSchema
    uniqueColumnsConstraint:(NSArray<NSString *> *)uniqueColumns {
    /*
  return [self executeQueryUsingBlock:^int(void *db) {
           if (![MSDBStorage tableExists:tableName inOpenedDatabase:db]) {
             NSString *uniqueContraintQuery = @"";
             if (uniqueColumns.count > 0) {
               uniqueContraintQuery = [NSString stringWithFormat:@", UNIQUE(%@)", [uniqueColumns componentsJoinedByString:@", "]];
             }
             NSString *createQuery =
                 [NSString stringWithFormat:@"CREATE TABLE \"%@\" (%@%@);", tableName,
                                            [MSDBStorage columnsQueryFromColumnsSchema:columnsSchema], uniqueContraintQuery];
             int result = [MSDBStorage executeNonSelectionQuery:createQuery inOpenedDatabase:db];
             if (result == SQLITE_OK) {
               MSLogVerbose([MSAppCenter logTag], @"Table %@ has been created", tableName);
             } else {
               MSLogError([MSAppCenter logTag], @"Failed to create table %@", tableName);
             }
             return result;
           }
           return SQLITE_OK;
         }] == SQLITE_OK;
     */
    return 0;
}

+ (NSString *)columnsQueryFromColumnsSchema:(MSDBColumnsSchema *)columnsSchema {
  NSMutableArray *columnQueries = [NSMutableArray new];

  // Browse columns.
  for (NSUInteger i = 0; i < columnsSchema.count; i++) {
    NSString *columnName = columnsSchema[i].allKeys[0];

    // Compute column query.
    [columnQueries
        addObject:[NSString stringWithFormat:@"\"%@\" %@", columnName, [columnsSchema[i][columnName] componentsJoinedByString:@" "]]];
  }
  return [columnQueries componentsJoinedByString:@", "];
}

+ (int)createTablesWithSchema:(MSDBSchema *)schema inOpenedDatabase:(void *)db {
    /*
  int result = SQLITE_OK;
  NSMutableArray *tableQueries = [NSMutableArray new];

  // Browse tables.
  for (NSString *tableName in schema) {

    // Optimization, don't even compute the query if the table already exists.
    if ([self tableExists:tableName inOpenedDatabase:db result:&result]) {
      if (result != SQLITE_OK) {
        return result;
      }
      continue;
    }

    // Compute table query.
    [tableQueries addObject:[NSString stringWithFormat:@"CREATE TABLE \"%@\" (%@);", tableName,
                                                       [MSDBStorage columnsQueryFromColumnsSchema:schema[tableName]]]];
  }

  // Create the tables.
  if (tableQueries.count > 0) {
    NSString *createTablesQuery = [tableQueries componentsJoinedByString:@"; "];
    result = [self executeNonSelectionQuery:createTablesQuery inOpenedDatabase:db];
  }
  return result;
     */
    return 0;
}

+ (NSDictionary *)columnsIndexes:(MSDBSchema *)schema {
  NSMutableDictionary *dbColumnsIndexes = [NSMutableDictionary new];
  for (NSString *tableName in schema) {
    NSMutableDictionary *tableColumnsIndexes = [NSMutableDictionary new];
    NSArray<NSDictionary *> *columns = schema[tableName];
    for (NSUInteger i = 0; i < columns.count; i++) {
      NSString *columnName = columns[i].allKeys[0];
      tableColumnsIndexes[columnName] = @(i);
    }
    dbColumnsIndexes[tableName] = tableColumnsIndexes;
  }
  return dbColumnsIndexes;
}

+ (BOOL)tableExists:(NSString *)tableName inOpenedDatabase:(void *)db {
  return [MSDBStorage tableExists:tableName inOpenedDatabase:db result:nil];
}

+ (BOOL)tableExists:(NSString *)tableName inOpenedDatabase:(void *)db result:(int *)result {
  NSString *query =
      [NSString stringWithFormat:@"SELECT COUNT(*) FROM \"sqlite_master\" WHERE \"type\"='table' AND \"name\"='%@';", tableName];
  NSArray<NSArray *> *entries = [MSDBStorage executeSelectionQuery:query inOpenedDatabase:db result:result];
  return entries.count > 0 && entries[0].count > 0 ? [(NSNumber *)entries[0][0] boolValue] : NO;
}

+ (NSUInteger)versionInOpenedDatabase:(void *)db result:(int *)result {
  NSArray<NSArray *> *entries = [MSDBStorage executeSelectionQuery:@"PRAGMA user_version" inOpenedDatabase:db result:result];
  return entries.count > 0 && entries[0].count > 0 ? [(NSNumber *)entries[0][0] unsignedIntegerValue] : 0;
}

+ (void)setVersion:(NSUInteger)version inOpenedDatabase:(void *)db {
  NSString *query = [NSString stringWithFormat:@"PRAGMA user_version = %lu", (unsigned long)version];
  [MSDBStorage executeNonSelectionQuery:query inOpenedDatabase:db];
}

+ (void)enableAutoVacuumInOpenedDatabase:(void *)db {
  NSArray<NSArray *> *result = [MSDBStorage executeSelectionQuery:@"PRAGMA auto_vacuum" inOpenedDatabase:db];
  int vacuumMode = 0;
  if (result.count > 0 && result[0].count > 0) {
    vacuumMode = [(NSNumber *)result[0][0] intValue];
  }
  BOOL autoVacuumDisabled = vacuumMode != 1;

  /*
   * If `auto_vacuum` is disabled, change it to `FULL` and then manually `VACUUM` the database. Per the SQLite docs, changing the state of
   * `auto_vacuum` must be followed by a manual `VACUUM` before the change can take effect (for more information,
   * see https://www.sqlite.org/pragma.html#pragma_auto_vacuum).
   */
  if (autoVacuumDisabled) {
    MSLogDebug([MSAppCenter logTag], @"Vacuuming database and enabling auto_vacuum");
    [MSDBStorage executeNonSelectionQuery:@"PRAGMA auto_vacuum = FULL; VACUUM" inOpenedDatabase:db];
  }
}

- (NSUInteger)countEntriesForTable:(NSString *)tableName condition:(nullable NSString *)condition {
  NSMutableString *countLogQuery = [NSMutableString stringWithFormat:@"SELECT COUNT(*) FROM \"%@\" ", tableName];
  if (condition.length > 0) {
    [countLogQuery appendFormat:@"WHERE %@", condition];
  }
  NSArray<NSArray<NSNumber *> *> *result = [self executeSelectionQuery:countLogQuery];
  return (result.count > 0) ? result[0][0].unsignedIntegerValue : 0;
}

- (int)executeNonSelectionQuery:(NSString *)query {
  return [self executeQueryUsingBlock:^int(void *db) {
    return [MSDBStorage executeNonSelectionQuery:query inOpenedDatabase:db];
  }];
}

+ (int)executeNonSelectionQuery:(NSString *)query inOpenedDatabase:(void *)db {
    /*
  char *errMsg = NULL;
  int result = sqlite3_exec(db, [query UTF8String], NULL, NULL, &errMsg);
  if (result == SQLITE_CORRUPT || result == SQLITE_NOTADB) {
    MSLogError([MSAppCenter logTag], @"A database file is corrupted: %d - %@", result, [NSString stringWithUTF8String:errMsg]);
  } else if (result == SQLITE_FULL) {
    MSLogDebug([MSAppCenter logTag], @"Query failed with error: %d - %@", result, [NSString stringWithUTF8String:errMsg]);
  } else if (result != SQLITE_OK) {
    MSLogError([MSAppCenter logTag], @"Query \"%@\" failed with error: %d - %@", query, result, [NSString stringWithUTF8String:errMsg]);
  }
  if (errMsg) {
    sqlite3_free(errMsg);
  }
  return result;
     */
    return 0;
}

- (NSArray<NSArray *> *)executeSelectionQuery:(NSString *)query {
  __block NSArray<NSArray *> *entries = nil;
  [self executeQueryUsingBlock:^int(void *db) {
    entries = [MSDBStorage executeSelectionQuery:query inOpenedDatabase:db];
    return 0;
  }];
  return entries ?: [NSArray<NSArray *> new];
}

+ (NSArray<NSArray *> *)executeSelectionQuery:(NSString *)query inOpenedDatabase:(void *)db {
  return [self executeSelectionQuery:query inOpenedDatabase:db result:nil];
}

+ (NSArray<NSArray *> *)executeSelectionQuery:(NSString *)query inOpenedDatabase:(void *)db result:(int *)result {
  NSMutableArray<NSMutableArray *> *entries = [NSMutableArray<NSMutableArray *> new];
    /*
  sqlite3_stmt *statement = NULL;
  int prepareResult = sqlite3_prepare_v2(db, [query UTF8String], -1, &statement, NULL);
  if (result != nil) {
    *result = prepareResult;
  }
  if (prepareResult == SQLITE_OK) {

    // Loop on rows.
    while (sqlite3_step(statement) == SQLITE_ROW) {
      NSMutableArray *entry = [NSMutableArray new];

      // Loop on columns.
      for (int i = 0; i < sqlite3_column_count(statement); i++) {
        id value = nil;

        switch (sqlite3_column_type(statement, i)) {
        case SQLITE_INTEGER:
          value = @(sqlite3_column_int(statement, i));
          break;
        case SQLITE_TEXT:
          value = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, i)];
          break;
        default:
          value = [NSNull null];
          break;
        }
        [entry addObject:value];
      }
      if (entry.count > 0) {
        [entries addObject:entry];
      }
    }
    sqlite3_finalize(statement);
  } else {
    MSLogError([MSAppCenter logTag], @"Query \"%@\" failed with error: %d - %@", query, prepareResult,
               [NSString stringWithUTF8String:sqlite3_errmsg(db)]);
  }
*/
  return entries;
}

- (void)customizeDatabase:(void *)__unused db {
}

- (void)migrateDatabase:(void *)__unused db fromVersion:(NSUInteger)__unused version {
}

- (void)setMaxStorageSize:(long)sizeInBytes completionHandler:(nullable void (^)(BOOL))completionHandler {
  /*
   int result;
  BOOL success;
  sqlite3 *db = [MSDBStorage openDatabaseAtFileURL:self.dbFileURL withResult:&result];
  if (!db) {
    return;
  }

  // Check the current number of pages in the database to determine whether the requested size will shrink the database.
  long currentPageCount = [MSDBStorage getPageCountInOpenedDatabase:db];
  MSLogDebug([MSAppCenter logTag], @"Found %ld pages in the database.", currentPageCount);
  long requestedMaxPageCount = sizeInBytes % self.pageSize ? sizeInBytes / self.pageSize + 1 : sizeInBytes / self.pageSize;
  if (currentPageCount > requestedMaxPageCount) {
    MSLogWarning([MSAppCenter logTag],
                 @"Cannot change database size to %ld bytes as it would cause a loss of data. "
                  "Maximum database size will not be changed.",
                 sizeInBytes);
    success = NO;
  } else {

    // Attempt to set the limit and check the page count to make sure the given limit works.
    result = [MSDBStorage setMaxPageCount:requestedMaxPageCount inOpenedDatabase:db];
    if (result != SQLITE_OK) {
      MSLogError([MSAppCenter logTag], @"Could not change maximum database size to %ld bytes. SQLite error code: %i", sizeInBytes, result);
      success = NO;
    } else {
      long currentMaxPageCount = [MSDBStorage getMaxPageCountInOpenedDatabase:db];
      long actualMaxSize = currentMaxPageCount * self.pageSize;
      if (requestedMaxPageCount != currentMaxPageCount) {
        MSLogError([MSAppCenter logTag], @"Could not change maximum database size to %ld bytes, current maximum size is %ld bytes.",
                   sizeInBytes, actualMaxSize);
        success = NO;
      } else {
        if (sizeInBytes == actualMaxSize) {
          MSLogInfo([MSAppCenter logTag], @"Changed maximum database size to %ld bytes.", actualMaxSize);
        } else {
          MSLogInfo([MSAppCenter logTag], @"Changed maximum database size to %ld bytes (next multiple of 4KiB).", actualMaxSize);
        }
        self.maxSizeInBytes = actualMaxSize;
        success = YES;
      }
    }
  }
  sqlite3_close(db);
    */
  if (completionHandler) {
    completionHandler(true);
  }
}

//+ (sqlite3 *)openDatabaseAtFileURL:(NSURL *)fileURL withResult:(int *)result {
//  sqlite3 *db = NULL;
//  *result = sqlite3_open_v2([[fileURL absoluteString] UTF8String], &db, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_URI, NULL);
//  if (*result != SQLITE_OK) {
//    MSLogError([MSAppCenter logTag], @"Failed to open database with result: %d.", *result);
//    return NULL;
//  }
//  return db;
//}
+ (long)getPageSizeInOpenedDatabase:(void *)db {
  return [MSDBStorage querySingleValue:@"PRAGMA page_size;" inOpenedDatabase:db];
}

+ (long)getPageCountInOpenedDatabase:(void *)db {
  return [MSDBStorage querySingleValue:@"PRAGMA page_count;" inOpenedDatabase:db];
}

+ (long)getMaxPageCountInOpenedDatabase:(void *)db {
  return [MSDBStorage querySingleValue:@"PRAGMA max_page_count;" inOpenedDatabase:db];
}

+ (long)querySingleValue:(NSString *)query inOpenedDatabase:(void *)db {
  NSArray<NSArray *> *rows = [MSDBStorage executeSelectionQuery:query inOpenedDatabase:db];
  return rows.count > 0 && rows[0].count > 0 ? [(NSNumber *)rows[0][0] longValue] : 0;
}

+ (int)setMaxPageCount:(long)maxPageCount inOpenedDatabase:(void *)db {
  NSString *statement = [NSString stringWithFormat:@"PRAGMA max_page_count = %ld;", maxPageCount];
  return [MSDBStorage executeNonSelectionQuery:statement inOpenedDatabase:db];
}

+ (int)configureSQLite {
    return 0; // sqlite3_config(SQLITE_CONFIG_URI, 1);
}

@end
