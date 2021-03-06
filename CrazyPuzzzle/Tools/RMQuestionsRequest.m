//
//  RMAnswersRequest.m
//  CrazyPuzzzle
//
//  Created by Ramonqlee on 12/1/13.
//  Copyright (c) 2013 xiaoran. All rights reserved.
//

#import "RMQuestionsRequest.h"
#import "ASIFormDataRequest.h"
#import "Utility.h"

#define CP_Words_Max_Length 16//允许的最大单词长度

#define kQuestionListUrl @"http://checknewversion.duapp.com/image/questionlist2.php"//请求问题列表url

#define kCategoryKey @"category"
@interface RMQuestionsRequest()
{
   
}

@end

@implementation RMQuestionsRequest
#pragma mark get image lists
Impl_Singleton(RMQuestionsRequest)
- (void)startAsynchronous:(NSString*)category
{
    if (self.category2QuestionArrayDict && self.category2QuestionArrayDict.count>0) {
        id obj = [self.category2QuestionArrayDict objectForKey:category];
        if (obj) {
            [[NSNotificationCenter defaultCenter]postNotificationName:QUESTION_RESPONSE_NOTIFICATION object:obj];
            return;
        }
    }
    
    self.category = category;
    
    NSURL *url = [NSURL URLWithString:kQuestionListUrl];
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    [ASIHTTPRequest setDefaultTimeOutSeconds:30];
    [request setDelegate:self];
    [request setPostValue:category forKey:kCategoryKey];
    [request startAsynchronous];
}

- (void)startAsynchronous
{
    [self startAsynchronous:kFreeGuessGame];
}

- (void)requestFinished:(ASIHTTPRequest *)request
{
    // Use when fetching text data
    //    NSString *responseString = [request responseString];
    
    // Use when fetching binary data
    NSData *responseData = [request responseData];
    
    //TODO::数据解析，及保存
    //服务器端数据打包，返回；
    //客户端解包，保存
    if (responseData) {
        NSError* error;
        
        NSString* aStr = [[NSString alloc] initWithData:responseData encoding:NSASCIIStringEncoding];
        aStr = [Utility decryptStr:aStr];
        NSData* aData = [aStr dataUsingEncoding: NSASCIIStringEncoding];
        id res = [NSJSONSerialization JSONObjectWithData:aData options:NSJSONReadingMutableContainers error:&error];
        
        NSArray* dataList = nil;
        
        if (res && [res isKindOfClass:[NSDictionary class]])
        {
            NSDictionary* dict = (NSDictionary*)res;
            id temp = [dict objectForKey:@"initAwardCoins"];
            if (temp && [temp isKindOfClass:[NSNumber class]]) {
                self.initAwardCoins = ((NSNumber*)temp).integerValue;
            }
            
            temp = [dict objectForKey:@"awardCoinsPerWord"];
            if (temp && [temp isKindOfClass:[NSNumber class]]) {
                self.awardCoinsPerWord = ((NSNumber*)temp).integerValue;
            }
            
            temp = [dict objectForKey:@"coinsPerTip"];
            if (temp && [temp isKindOfClass:[NSNumber class]]) {
                self.coinsPerTip = ((NSNumber*)temp).integerValue;
            }
            
            temp = [dict objectForKey:@"coinsForUnlockCategory"];
            if (temp && [temp isKindOfClass:[NSNumber class]]) {
                self.coinsForUnlockCategory = ((NSNumber*)temp).integerValue;
            }
            
            dataList = [dict objectForKey:@"data"];
        }
        
        if (dataList) {
            
            NSMutableArray* questionsArray = [[NSMutableArray alloc]init];
            
            [questionsArray addObjectsFromArray:(NSArray*)dataList];
            [self postProcess:questionsArray];
            
            //map it
            if (!self.category2QuestionArrayDict) {
                _category2QuestionArrayDict = [NSMutableDictionary new];
            }
            [self.category2QuestionArrayDict setObject:questionsArray forKey:self.category];
            
            //bingo,now read image list
            [[NSNotificationCenter defaultCenter]postNotificationName:QUESTION_RESPONSE_NOTIFICATION object:questionsArray];
        }
    }
}
    //过滤超长的单词
-(void)postProcess:(NSMutableArray*)questionsArray
{
    for (int i= questionsArray.count-1; i>=0; i--) {
        if ([[questionsArray objectAtIndex:i]length]>CP_Words_Max_Length) {
            [questionsArray removeObjectAtIndex:i];
        }
    }
}
- (void)requestFailed:(ASIHTTPRequest *)request
{
    NSError *error = [request error];
    NSLog(@"%@",error);
}
@end
