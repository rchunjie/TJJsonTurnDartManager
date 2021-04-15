//
//  TJJsonConversionDart.m
//  TJJsonTranConversionDart
//
//  Created by 任春节 on 2021/4/12.
//

#import "TJJSONConversionDart.h"

@interface TJJSONConversionDart ()

@property(nonatomic,strong)NSMutableArray <NSString *>*dataJsonArray;
///
@property(nonatomic,copy)void (^configBlock)(NSString *path,NSString *joiningJson,NSError *error);
/// 输出
@property(nonatomic,strong)NSString *outPath;
/// 输出文件名
@property(nonatomic,strong)NSString *fileName;
/// class 头拼接
@property(nonatomic,strong)NSString *classHeader;
/// class 尾部拼接
@property(nonatomic,strong)NSString *classEnd;
/// 解析数据
@property(nonatomic,strong)NSMutableString *dartJson;
/// 存储List解析方法数据
@property(nonatomic,strong)NSMutableDictionary *listMethods;

@end

@implementation TJJSONConversionDart

+ (instancetype)configOutPath:(NSString *)outPath fileName:(NSString *)fileName block:(void (^)(NSString * _Nonnull, NSString * _Nonnull, NSError * _Nonnull))block{
    TJJSONConversionDart *dart = [[TJJSONConversionDart alloc] init];
    dart.configBlock = block;
    dart.outPath = outPath;
    dart.fileName = fileName;
    return dart;
}

+ (instancetype)configBlock:(void(^)(NSString *path,NSString *joiningJson,NSError *error))block{
    // Documents
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docPath = [paths objectAtIndex:0];
    return [TJJSONConversionDart configOutPath:docPath fileName:@"TJDart.dart" block:block];
}

- (instancetype)init{
    if (self = [super init]) {
        self.classHeader = @"TJ";
        self.classEnd = @"Model";
        self.fileName = @"TJDart.dart";
    }
    return self;
}

/// 更新文件输出路径
/// @param outPath 输出路径
- (void)updateOutPath:(NSString *)outPath{
    self.outPath = outPath;
}

/// 更新文件名
/// @param fileName 文件名
- (void)updateFileName:(NSString *)fileName{
    if (![fileName hasSuffix:@".dart"]) {
        fileName = [NSString stringWithFormat:@"%@.dart",fileName];
    }
    self.fileName = fileName;
}

/// class头更新
/// @param classHeader class头
- (void)updateClassHeader:(NSString *)classHeader{
    self.classHeader = classHeader;
}
/// class尾部拼接更新
/// @param end class尾部名字
- (void)updateClassEnd:(NSString *)end{
    self.classEnd = end;
}

/// json解析
/// @param json 需要解析的数据
/// @param className 类名
- (void)jsonDataToDealWith:(id)json className:(NSString *)className{
    self.dartJson = @"".mutableCopy;
    [self.listMethods removeAllObjects];
    [self.dataJsonArray removeAllObjects];
    NSString * joiningJson = [self _jsonDataToDealWith:json className:className];
    for (NSInteger i = self.dataJsonArray.count; i > 0; i --) {
        NSString *parsingJson = self.dataJsonArray[i-1];
        NSArray <NSString *>*parsingArray = [parsingJson componentsSeparatedByString:@"{"];
        if (parsingArray.count > 0) {
            NSString *className = parsingArray.firstObject;
            className = [className stringByReplacingOccurrencesOfString:@"class" withString:@""];
            className = [className stringByReplacingOccurrencesOfString:@" " withString:@""];
            if ([self.listMethods objectForKey:className]) {
                NSString *arrayJson = [self _getArrayObjcClass:className];
                NSMutableString *_parsingJson = parsingJson.mutableCopy;
                [_parsingJson insertString:[NSString stringWithFormat:@"static List<%@>arrayMapToJsonModels(List<dynamic> jsons){\n%@\n}",className,arrayJson] atIndex:parsingJson.length - 1];
                parsingJson = _parsingJson;
            }
        }
        [self.dartJson appendString:parsingJson];
        [self.dartJson appendString:@"\n"];
    }
    [self.dartJson appendString:joiningJson];
    
    NSString *path = @"";
    NSError *error = nil;
    if (self.outPath.length <= 0) {
        NSArray * documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString * documentDirectory = [documentPaths objectAtIndex:0];
    
        self.outPath = documentDirectory;
    }
    if (self.outPath.length > 0 && self.fileName.length > 0) {
        path = [self.outPath stringByAppendingPathComponent:self.fileName];
        BOOL isWriteString =[self.dartJson writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&error];
        if (isWriteString) {
            NSLog(@"string 文件写入成功");
        }else{
            NSLog(@"写入失败");
        };
    }
    !self.configBlock?:self.configBlock(path,self.dartJson,error);
}

- (NSString *)_jsonDataToDealWith:(id)json className:(NSString *)className{
    NSMutableString *paramsString = [[NSMutableString alloc] init];
    id dic;
    if ([json isKindOfClass:[NSString class]]) {
        dic = [self dictionaryWithJsonString:json];
    }
    if ([json isKindOfClass:[NSDictionary class]]) {
        dic = json;
    }
    if ([json isKindOfClass:[NSArray class]]) {
        dic = json;
    }
    NSMutableString *framJson = [[NSMutableString alloc] init];
    if ([dic isKindOfClass:[NSDictionary class]] || [dic isKindOfClass:[NSArray class]]) {
        if ([(NSDictionary *)dic isKindOfClass:[NSDictionary class]]) {
            [dic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                if ([obj isKindOfClass:[NSDictionary class]]) {
                    NSString *keyJsonClassName = [self _getClassNameKey:key];
                    NSString *jsonClassName = keyJsonClassName;
                    [self.dataJsonArray addObject:[self _jsonDataToDealWith:obj className:jsonClassName]];
                    
                    [paramsString appendFormat:@"\n%@ %@;\n",jsonClassName,key];
                }
                else if([obj isKindOfClass:[NSArray class]]){
                    NSString *keyJsonClassName = [self _jsonFromArray:obj keyJsonClassName:key];
                    [paramsString appendFormat:@"\nList<%@> %@;\n",keyJsonClassName,key];
                    [self.listMethods setObject:obj forKey:keyJsonClassName];
                }
                else{
                    [paramsString appendFormat:@"%@", [NSString stringWithFormat:@"\n%@ %@;\n",[self _getValueTypes:obj],key]];
                }
                [framJson appendString:[NSString stringWithFormat:@"\n%@\n",[self _getFramJsonDicKey:key obj:obj mapName:@"map"]]];
            }];
        }else{
            [paramsString appendString:[NSString stringWithFormat:@"\nList<%@> list;\n",[self _jsonFromArray:dic keyJsonClassName:@"list"]]];
        }
    }else{
        
        !self.configBlock?:self.configBlock(@"",@"",[[NSError alloc] initWithDomain:NSCocoaErrorDomain code:-1 userInfo:@{@"msg":@"数据错误"}]);
        return @"";
    }
    
    
    NSString *framJson01 = [NSString stringWithFormat:@"%@.formJson({Map<String, dynamic> map}){\n%@\n}",className,framJson];
    NSString *arrayMapToJson = @"";
    NSString * dartJson = [NSString stringWithFormat:@"class %@ {\n%@\n%@\n%@\n}",className,paramsString,framJson01,arrayMapToJson];
    
    return dartJson;
}

- (NSString *)_getArrayObjcClass:(NSString *)objcClass{
    NSMutableString *jsonModels = [[NSMutableString alloc] init];
    [jsonModels appendFormat:@"\nList<%@> models = [];\n",objcClass];
    [jsonModels appendFormat:@"jsons.forEach((element) {models.add(%@.formJson(map: element));}); return models;",objcClass];
    return jsonModels;
}

- (NSString *)_jsonFromArray:(NSArray *)dataArray keyJsonClassName:(NSString *)key{
    NSString *keyJsonClassName = [self _getClassNameKey:key];
    if ([dataArray.firstObject isKindOfClass:[NSDictionary class]] ||
        [dataArray.firstObject isKindOfClass:[NSString class]]) {
        [self.dataJsonArray addObject:[self _jsonDataToDealWith:dataArray.firstObject className:keyJsonClassName]];
    }
    return  keyJsonClassName;
}

- (NSString *)_getFramJsonDicKey:(NSString *)key obj:(id)obj mapName:(NSString *)mapName{
    NSString *toJson  = @"";
    if ([obj isKindOfClass:[NSString class]]) {
        toJson = @".toString()";
    }
    if ([obj isKindOfClass:[NSArray class]]) {
        NSString *keyJsonClassName = [self _getClassNameKey:key];
        NSString *json = [NSString stringWithFormat:@"if (%@['%@'] != null){\n   %@ = %@.arrayMapToJsonModels(%@['%@']);\n}\n",mapName,key,key,keyJsonClassName,mapName,key];
        return json;
    } else if([obj isKindOfClass:[NSDictionary class]]){
        NSString *keyJsonClassName = key;
        if ([obj isKindOfClass:[NSDictionary class]]) {
            keyJsonClassName = [self _getClassNameKey:keyJsonClassName];
        }
        NSString *json = [NSString stringWithFormat:@"if (%@['%@'] != null){\n%@=%@.formJson(map: %@['%@']);\n};",mapName,key,key,keyJsonClassName,mapName,key];
        return json;
    }
    else{
        NSString *json = [NSString stringWithFormat:@"if (%@['%@'] != null){\n   %@ = %@['%@']%@;\n}\n",mapName,key,key,mapName,key,toJson];
        return json;
    }
    
}

- (NSString *)_getClassNameKey:(NSString *)key{
    if (key.length > 1) {
        NSString *keyJsonClassName = key;
        if (keyJsonClassName.length > 1) {
            keyJsonClassName  = [NSString stringWithFormat:@"%@%@%@%@",self.classHeader,[[keyJsonClassName substringToIndex:1] uppercaseString],[keyJsonClassName substringFromIndex:1],self.classEnd];
        }
        return keyJsonClassName;
    }
    return key;
}

- (NSString *)_getValueTypes:(id)value{
    if ([value isKindOfClass:[NSDictionary class]]) {
        return  @"Map";
    }
    if ([value isKindOfClass:[NSNumber class]]) {
        if ([self isBoolNumber:value]) {
            return @"bool";
        }
        if (strcmp([value objCType], @encode(float)) == 0) {
            return @"float";
        }
        if (strcmp([value objCType], @encode(double)) == 0) {
            return @"double";
        }
        if (strcmp([value objCType], @encode(int))== 0) {
            return @"int";
        }
        if (strcmp([value objCType], @encode(long))== 0) {
            return @"int";
        }
        return @"int";
    }
    return @"String";
}

- (BOOL) isBoolNumber:(NSNumber *)num

{
    CFTypeID boolID = CFBooleanGetTypeID(); // the type ID of CFBoolean
    
    CFTypeID numID = CFGetTypeID((__bridge CFTypeRef)(num)); // the type ID of num
    
    return numID == boolID;
    
}
- (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString
{
    if (jsonString == nil) {return nil;}
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                        options:NSJSONReadingMutableContainers
                                                          error:&error];
    if(error){
        return @{};
    }
    return dic;
}
- (NSMutableArray<NSString *> *)dataJsonArray{
    if (!_dataJsonArray) {
        _dataJsonArray = [NSMutableArray array];
    }
    return _dataJsonArray;
}

- (NSMutableString *)dartJson{
    if (!_dartJson) {
        _dartJson = [[NSMutableString alloc] init];
    }
    return _dartJson;
}

- (NSMutableDictionary *)listMethods{
    if (!_listMethods) {
        _listMethods = [NSMutableDictionary dictionary];
    }
    return _listMethods;
}
@end
