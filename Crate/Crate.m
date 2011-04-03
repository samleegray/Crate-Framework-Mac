/*
 *  Cloudie.cpp
 *  libcurl console tests
 *
 *  Created by Sam Gray on 11/29/10.
 *  Copyright 2010 Sam Gray. All rights reserved.
 *
 */

#include "Crate.h"

#pragma mark -
#pragma mark libcurl callbacks

int uploadProgress(void *s, double t, double d, double ultotal, double ulnow)
{
    Crate *selfCrate = (Crate *)s;
    
	int size = 100;
	double fractionDownloaded = ulnow / ultotal;
	int amountFull = round(fractionDownloaded * size);
    
    if(amountFull != [selfCrate lastPercent])
    {
        [[selfCrate delegate] uploadProgress:amountFull];
        [selfCrate setLastPercent:amountFull];
    }
    
	return 0;
}

int downloadProgress(void *s, double t, double d, double ultotal, double ulnow)
{
    Crate *selfCrate = (Crate *)s;
    
	int size = 100;
	double fractionDownloaded = d / t;
	int amountFull = round(fractionDownloaded * size);
    
    if(amountFull != [selfCrate lastPercent])
    {
        [[selfCrate delegate] downloadProgress:amountFull];
        [selfCrate setLastPercent:amountFull];
    }
    
	return 0;
}

size_t writefunc(void *ptr, size_t size, size_t nmemb, void *s)
{	
    Crate *selfCrate = (Crate *)s;
    
    NSMutableString *stringToParse = [[NSMutableString alloc] initWithUTF8String:(const char *)ptr];
    
    if(stringToParse != nil)
    {
        int deleteableAmount = [stringToParse length] - nmemb;
        [stringToParse deleteCharactersInRange:NSMakeRange([stringToParse length] - deleteableAmount, deleteableAmount)];
        const char *stringToWrite = [stringToParse UTF8String];
    }
	
    SBJsonParser *parser = [[SBJsonParser alloc] init];
    [selfCrate setJsonData:[parser objectWithString:stringToParse]];
    [parser release];
    [stringToParse release];
	
	return size*nmemb;
}

size_t writefunc_file(void *ptr, size_t size, size_t nmemb, char *s)
{	    
    Crate *selfCrate = (Crate *)s;
    fwrite(ptr, size, nmemb, [selfCrate currentFile]);
	
	return size*nmemb;
}

@implementation Crate

@synthesize jsonData;
@synthesize currentFile;
@synthesize delegate;
@synthesize lastPercent;

-(id)init
{
	self = [super init];
	if (self != nil) 
	{
		stringBuffer = NULL;
		
		curl_global_init(CURL_GLOBAL_ALL);
		curl = curl_easy_init();
		
		return(self);
	}
	
	return(nil);
}

-(id)initWithDelegate:(id <CrateDelegate>)aDelegate
{
    self = [super init];
    if (self != nil) 
    {
        stringBuffer = NULL;
        curl_global_init(CURL_GLOBAL_ALL);
        curl = curl_easy_init();
        delegate = aDelegate;
        
        return(self);
    }
    
    return(nil);
}

-(NSDictionary *)uploadFile:(NSString *)filePathString username:(NSString *)usernameString password:(NSString *)passwordString crate:(int)crateID
{
	CURLcode res2;
	
    NSString *userpwdString = [[NSString alloc] initWithFormat:@"%@:%@", usernameString, passwordString];
	const char *filePath = [filePathString UTF8String];
	
	struct curl_httppost *formpost2=NULL;
	struct curl_httppost *lastptr2=NULL;
	struct curl_slist *headerlist2=NULL;
	static const char buf2[] = "Content-Type: multipart/form-data";
    
    NSString *crateIDString = [[NSString alloc] initWithFormat:@"%d", crateID];
	
	curl_formadd(&formpost2,
				 &lastptr2,
				 CURLFORM_COPYNAME, "crate_id",
				 CURLFORM_COPYCONTENTS, [crateIDString UTF8String],
				 CURLFORM_END);
	
	curl_formadd(&formpost2,
				 &lastptr2,
				 CURLFORM_COPYNAME, "file",
				 CURLFORM_FILE, filePath,
				 CURLFORM_END);
	
	headerlist2 = curl_slist_append(headerlist2, buf2);
	if(curl) 
	{
		curl_easy_setopt(curl, CURLOPT_URL, CRATE_UPLOAD_URL);
        curl_easy_setopt(curl, CURLOPT_USERPWD, [userpwdString UTF8String]);
		curl_easy_setopt(curl, CURLOPT_HTTPPOST, formpost2);
		curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, writefunc);
		curl_easy_setopt(curl, CURLOPT_WRITEDATA, (void *)self);
		curl_easy_setopt(curl, CURLOPT_NOPROGRESS, 0L);
		curl_easy_setopt(curl, CURLOPT_PROGRESSFUNCTION, uploadProgress);
        curl_easy_setopt(curl, CURLOPT_PROGRESSDATA, (void *)self);
		
		res2 = curl_easy_perform(curl);
        
        curl_easy_reset(curl);
		
		curl_formfree(formpost2);
		curl_slist_free_all (headerlist2);
	}
   
    [userpwdString release];
    [crateIDString release];
    
	return(jsonData);
}

-(NSDictionary *)validateUser:(NSString *)usernameString password:(NSString *)passwordString
{
	CURLcode res2;
	
	struct curl_httppost *formpost2=NULL;
	struct curl_httppost *lastptr2=NULL;
	struct curl_slist *headerlist2=NULL;
    static const char *buf2 = "";
    
    NSString *userpwdString = [[NSString alloc] initWithFormat:@"%@:%@", usernameString, passwordString];
    
	headerlist2 = curl_slist_append(headerlist2, buf2);
	if(curl) 
	{
        curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1L);
		curl_easy_setopt(curl, CURLOPT_URL, CRATE_AUTH_URL);
        curl_easy_setopt(curl, CURLOPT_USERPWD, [userpwdString UTF8String]);
		curl_easy_setopt(curl, CURLOPT_HTTPGET, formpost2);
		curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, writefunc);
		curl_easy_setopt(curl, CURLOPT_WRITEDATA, (void *)self);
		res2 = curl_easy_perform(curl);
        curl_easy_reset(curl);
		
		curl_formfree(formpost2);
		curl_slist_free_all (headerlist2);
	}
    
    [userpwdString release];
	
	return(jsonData);
}

-(NSDictionary *)downloadFile:(NSString *)shortURL destination:(NSString *)toDirectory
{
	CURLcode res2;
	
	struct curl_httppost *formpost2=NULL;
	struct curl_httppost *lastptr2=NULL;
	struct curl_slist *headerlist2=NULL;
    static const char *buf2 = "";
    
    NSString *downloadURL = [[NSString alloc] initWithFormat:@"%s%@", CRATE_SHORT_URL_BASE, shortURL];
	
	headerlist2 = curl_slist_append(headerlist2, buf2);
	if(curl) 
	{
        currentFile = fopen([toDirectory UTF8String], "wb");
        curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1L);
		curl_easy_setopt(curl, CURLOPT_URL, [downloadURL UTF8String]);
		curl_easy_setopt(curl, CURLOPT_HTTPGET, formpost2);
		curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, writefunc_file);
		curl_easy_setopt(curl, CURLOPT_WRITEDATA, (void *)self);
        curl_easy_setopt(curl, CURLOPT_NOPROGRESS, 0L);
        curl_easy_setopt(curl, CURLOPT_PROGRESSFUNCTION, downloadProgress);
        curl_easy_setopt(curl, CURLOPT_PROGRESSDATA, (void *)self);
		res2 = curl_easy_perform(curl);
        curl_easy_reset(curl);
		
		curl_formfree(formpost2);
		curl_slist_free_all (headerlist2);
	}
	
    fclose(currentFile);
    
    [downloadURL release];
	
	return(jsonData);
}

-(NSDictionary *)listFiles:(NSString *)usernameString password:(NSString *)passwordString
{
	CURLcode res2;
	
	struct curl_httppost *formpost2=NULL;
	struct curl_httppost *lastptr2=NULL;
	struct curl_slist *headerlist2=NULL;
    static const char *buf2 = "";
    
    NSString *userpwdString = [[NSString alloc] initWithFormat:@"%@:%@", usernameString, passwordString];
    
	headerlist2 = curl_slist_append(headerlist2, buf2);
	if(curl) 
	{
		curl_easy_setopt(curl, CURLOPT_URL, CRATE_LISTFILES_URL);
        curl_easy_setopt(curl, CURLOPT_USERPWD, [userpwdString UTF8String]);
		curl_easy_setopt(curl, CURLOPT_HTTPGET, formpost2);
		curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, writefunc);
		curl_easy_setopt(curl, CURLOPT_WRITEDATA, (void *)self);
		res2 = curl_easy_perform(curl);
        curl_easy_reset(curl);
		
		curl_formfree(formpost2);
		curl_slist_free_all (headerlist2);
	}
	
    [userpwdString release];
	
	return(jsonData);
}

-(NSDictionary *)showFile:(int)fileID username:(NSString *)usernameString password:(NSString *)passwordString
{
	CURLcode res2;
	
	struct curl_httppost *formpost2=NULL;
	struct curl_httppost *lastptr2=NULL;
	struct curl_slist *headerlist2=NULL;
    static const char *buf2 = "";
    
    NSString *userpwdString = [[NSString alloc] initWithFormat:@"%@:%@", usernameString, passwordString];
    
    NSString *url = [[NSString alloc] initWithFormat:@"%s%d%@", CRATE_SHOWFILE_URL, fileID, @".json"];
    
	headerlist2 = curl_slist_append(headerlist2, buf2);
	if(curl) 
	{
		curl_easy_setopt(curl, CURLOPT_URL, [url UTF8String]);
        curl_easy_setopt(curl, CURLOPT_USERPWD, [userpwdString UTF8String]);
		curl_easy_setopt(curl, CURLOPT_HTTPGET, formpost2);
		curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, writefunc);
		curl_easy_setopt(curl, CURLOPT_WRITEDATA, (void *)self);
		res2 = curl_easy_perform(curl);
        curl_easy_reset(curl);
		
		curl_formfree(formpost2);
		curl_slist_free_all (headerlist2);
	}
    
    [url release];
    [userpwdString release];
	
	return(jsonData);
}

-(NSDictionary *)deleteFile:(int)fileID username:(NSString *)usernameString password:(NSString *)passwordString
{
	CURLcode res2;
	
	struct curl_httppost *formpost2=NULL;
	struct curl_httppost *lastptr2=NULL;
	struct curl_slist *headerlist2=NULL;
    static const char *buf2 = "";
    
    NSString *userpwdString = [[NSString alloc] initWithFormat:@"%@:%@", usernameString, passwordString];
    
    NSString *url = [[NSString alloc] initWithFormat:@"%s%d%@", CRATE_DELETEFILE_URL, fileID, @".json"];
    
	headerlist2 = curl_slist_append(headerlist2, buf2);
	if(curl) 
	{
		curl_easy_setopt(curl, CURLOPT_URL, [url UTF8String]);
        curl_easy_setopt(curl, CURLOPT_USERPWD, [userpwdString UTF8String]);
		curl_easy_setopt(curl, CURLOPT_HTTPPOST, formpost2);
		curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, writefunc);
		curl_easy_setopt(curl, CURLOPT_WRITEDATA, (void *)self);
		res2 = curl_easy_perform(curl);
        curl_easy_reset(curl);
		
		curl_formfree(formpost2);
		curl_slist_free_all (headerlist2);
	}
	
    [url release];
    [userpwdString release];
	
	return(jsonData);
}

-(NSDictionary *)createCrate:(NSString *)crateName username:(NSString *)usernameString password:(NSString *)passwordString
{
	CURLcode res2;
	
	struct curl_httppost *formpost2=NULL;
	struct curl_httppost *lastptr2=NULL;
	struct curl_slist *headerlist2=NULL;
    static const char *buf2 = "";
    
    NSString *userpwdString = [[NSString alloc] initWithFormat:@"%@:%@", usernameString, passwordString];
    
    curl_formadd(&formpost2,
				 &lastptr2,
				 CURLFORM_COPYNAME, "name",
				 CURLFORM_COPYCONTENTS, [crateName UTF8String],
				 CURLFORM_END);
    
	headerlist2 = curl_slist_append(headerlist2, buf2);
	if(curl) 
	{
		curl_easy_setopt(curl, CURLOPT_URL, CRATE_CREATECRATE_URL);
        curl_easy_setopt(curl, CURLOPT_USERPWD, [userpwdString UTF8String]);
		curl_easy_setopt(curl, CURLOPT_HTTPPOST, formpost2);
		curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, writefunc);
		curl_easy_setopt(curl, CURLOPT_WRITEDATA, (void *)self);
		res2 = curl_easy_perform(curl);
        curl_easy_reset(curl);
		
		curl_formfree(formpost2);
		curl_slist_free_all (headerlist2);
	}
	
    [userpwdString release];
	
	return(jsonData);
}

-(NSDictionary *)listCrates:(NSString *)usernameString password:(NSString *)passwordString
{
	CURLcode res2;
	
	struct curl_httppost *formpost2=NULL;
	struct curl_httppost *lastptr2=NULL;
	struct curl_slist *headerlist2=NULL;
    static const char *buf2 = "";
    
    NSString *userpwdString = [[NSString alloc] initWithFormat:@"%@:%@", usernameString, passwordString];
    
	headerlist2 = curl_slist_append(headerlist2, buf2);
	if(curl) 
	{
		curl_easy_setopt(curl, CURLOPT_URL, CRATE_LISTCRATES_URL);
        curl_easy_setopt(curl, CURLOPT_USERPWD, [userpwdString UTF8String]);
		curl_easy_setopt(curl, CURLOPT_HTTPGET, formpost2);
		curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, writefunc);
		curl_easy_setopt(curl, CURLOPT_WRITEDATA, (void *)self);
		res2 = curl_easy_perform(curl);
        curl_easy_reset(curl);
		
		curl_formfree(formpost2);
		curl_slist_free_all (headerlist2);
	}
	
    [userpwdString release];
	
	return(jsonData);
}

-(NSDictionary *)renameCrate:(int)crateID toName:(NSString *)newName username:(NSString *)usernameString password:(NSString *)passwordString
{
	CURLcode res2;
	
	struct curl_httppost *formpost2=NULL;
	struct curl_httppost *lastptr2=NULL;
	struct curl_slist *headerlist2=NULL;
    static const char *buf2 = "";
    
    NSString *userpwdString = [[NSString alloc] initWithFormat:@"%@:%@", usernameString,
            passwordString];
    NSString *url = [[NSString alloc] initWithFormat:@"%s%d%@", CRATE_RENAMECRATE_URL, crateID, @".json"];
    
    
    curl_formadd(&formpost2,
				 &lastptr2,
				 CURLFORM_COPYNAME, "name",
				 CURLFORM_COPYCONTENTS, [newName UTF8String],
				 CURLFORM_END);
    
	headerlist2 = curl_slist_append(headerlist2, buf2);
	if(curl) 
	{
		curl_easy_setopt(curl, CURLOPT_URL, [url UTF8String]);
        curl_easy_setopt(curl, CURLOPT_USERPWD, [userpwdString UTF8String]);
		curl_easy_setopt(curl, CURLOPT_HTTPPOST, formpost2);
		curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, writefunc);
		curl_easy_setopt(curl, CURLOPT_WRITEDATA, (void *)self);
		res2 = curl_easy_perform(curl);
        curl_easy_reset(curl);
		
		curl_formfree(formpost2);
		curl_slist_free_all (headerlist2);
	}
	
    [userpwdString release];
    [url release];
	
	return(jsonData);
}

-(NSDictionary *)deleteCrate:(int)crateID username:(NSString *)usernameString password:(NSString *)passwordString
{
	CURLcode res2;
	
	struct curl_httppost *formpost2=NULL;
	struct curl_httppost *lastptr2=NULL;
	struct curl_slist *headerlist2=NULL;
    static const char *buf2 = "";
    
    NSString *userpwdString = [[NSString alloc] initWithFormat:@"%@:%@", usernameString, passwordString];
    
    NSString *url = [[NSString alloc] initWithFormat:@"%s%d%@", CRATE_DELETECRATE_URL, crateID, @".json"];
    
	headerlist2 = curl_slist_append(headerlist2, buf2);
	if(curl) 
	{
		curl_easy_setopt(curl, CURLOPT_URL, [url UTF8String]);
        curl_easy_setopt(curl, CURLOPT_USERPWD, [userpwdString UTF8String]);
		curl_easy_setopt(curl, CURLOPT_HTTPPOST, formpost2);
		curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, writefunc);
		curl_easy_setopt(curl, CURLOPT_WRITEDATA, (void *)self);
		res2 = curl_easy_perform(curl);
        curl_easy_reset(curl);
		
		curl_formfree(formpost2);
		curl_slist_free_all (headerlist2);
	}
	
    [url release];
    [userpwdString release];
	
	return(jsonData);
}

-(const char *)convertImage:(NSString *)filePathString
{
	NSImage *image = [[NSImage alloc] initWithContentsOfFile:filePathString];
	NSData *data = [[NSBitmapImageRep imageRepWithData:
					 [image TIFFRepresentation]]
					representationUsingType:NSPNGFileType 
					properties:nil];
	NSString *uniqueString = [[NSProcessInfo processInfo] globallyUniqueString];
	NSMutableString *uniqueFilename = [NSMutableString stringWithFormat:@"%@.jpg", uniqueString];
	NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:uniqueFilename];
	[data writeToURL:[NSURL fileURLWithPath:filePath] atomically:NO];
    
    [image release];
	
	return([filePath UTF8String]);
}

-(const char *)makeMD5:(NSString *)stringToMD5
{
	const char *CstringToMD5 = [stringToMD5 UTF8String];
	unsigned char md5pass[16];
	CC_MD5(CstringToMD5, strlen(CstringToMD5), md5pass);
	int i;
	NSMutableString *mutString = [NSMutableString string];
	for(i = 0; i <= 16; i++)
	{
		[mutString appendFormat:@"%02X", md5pass[i]];
	}
	
	[mutString deleteCharactersInRange:NSMakeRange([mutString length]-2, 2)];
	
	return([[mutString lowercaseString] UTF8String]);
}

-(void)dealloc
{
	curl_easy_cleanup(curl);
	curl_global_cleanup();
	[grabURL release];
	[super dealloc];
}

@end