/*
 *  Cloudie.h
 *  libcurl console tests
 *
 *  Created by Sam Gray on 11/29/10.
 *  Copyright 2010 Sam Gray. All rights reserved.
 *
 */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include <curl/curl.h>
#include <curl/types.h>
#include <curl/easy.h>

#import <JSON/JSON.h>
#import <CommonCrypto/CommonDigest.h>
#import "CrateDelegate.h"

#define CRATE_BASEURL_API "https://api.letscrate.com/1/"
#define CRATE_AUTH_URL CRATE_BASEURL_API "users/authenticate.json"
#define CRATE_UPLOAD_URL CRATE_BASEURL_API "files/upload.json"
#define CRATE_LISTFILES_URL CRATE_BASEURL_API "files/list.json"
#define CRATE_SHOWFILE_URL CRATE_BASEURL_API "files/show/"
#define CRATE_DELETEFILE_URL CRATE_BASEURL_API "files/destroy/"
#define CRATE_CREATECRATE_URL CRATE_BASEURL_API "crates/add.json"
#define CRATE_LISTCRATES_URL CRATE_BASEURL_API "crates/list.json"
#define CRATE_RENAMECRATE_URL CRATE_BASEURL_API "crates/rename/"
#define CRATE_DELETECRATE_URL CRATE_BASEURL_API "crates/destroy/"

#define CRATE_SHORT_URL_BASE "http://lts.cr/"

#define CLOUDIE_SUCCESS 0
#define CLOUDIE_FAIL 1

@interface Crate : NSObject
{
    id <CrateDelegate> delegate;
    FILE *currentFile;
    NSDictionary *jsonData;
    int lastPercent;
    
@private
	CURL *curl;
	char *stringBuffer;
	NSString *grabURL;
}
@property(assign, readwrite)NSDictionary *jsonData;
@property(assign, readwrite)FILE *currentFile;
@property(assign, readwrite)id<CrateDelegate> delegate;
@property(assign, readwrite)int lastPercent;

-(id)initWithDelegate:(id <CrateDelegate>)aDelegate;
-(NSDictionary *)uploadFile:(NSString *)filePathString username:(NSString *)usernameString password:(NSString *)passwordString crate:(int)crateID;
-(NSDictionary *)validateUser:(NSString *)usernameString password:(NSString *)passwordString;
-(NSDictionary *)downloadFile:(NSString *)shortURL destination:(NSString *)toDirectory;
-(NSDictionary *)listFiles:(NSString *)usernameString password:(NSString *)passwordString;
-(NSDictionary *)showFile:(int)fileID username:(NSString *)usernameString password:(NSString *)passwordString;
-(NSDictionary *)deleteFile:(int)fileID username:(NSString *)usernameString password:(NSString *)passwordString;
-(NSDictionary *)createCrate:(NSString *)crateName username:(NSString *)usernameString password:(NSString *)passwordString;
-(NSDictionary *)listCrates:(NSString *)usernameString password:(NSString *)passwordString;
-(NSDictionary *)renameCrate:(int)crateID toName:(NSString *)newName username:(NSString *)usernameString password:(NSString *)passwordString;
-(NSDictionary *)deleteCrate:(int)crateID username:(NSString *)usernameString password:(NSString *)passwordString;

-(const char *)convertImage:(NSString *)filePathString;
-(const char *)makeMD5:(NSString *)stringToMD5;

@end

int uploadProgress(void *blah, double t, double d, double ultotal, double ulnow);
int downloadProgress(void *blah, double t, double d, double ultotal, double ulnow);
size_t writefunc(void *ptr, size_t size, size_t nmemb, void *s);
size_t writefunc_file(void *ptr, size_t size, size_t nmemb, char *s);
