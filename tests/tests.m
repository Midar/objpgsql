/*
 * Copyright (c) 2012, 2013, 2014, 2015, 2016, 2017
 *   Jonathan Schleifer <js@heap.zone>
 *
 * https://heap.zone/git/objpgsql.git
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice is present in all copies.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#import <ObjFW/ObjFW.h>

#import "PGConnection.h"
#import "PGConnectionFailedException.h"

@interface Test: OFObject
{
	PGConnection *connection;
}
@end

OF_APPLICATION_DELEGATE(Test)

@implementation Test
- (void)applicationDidFinishLaunching
{
	OFString *username =
	    [[OFApplication environment] objectForKey: @"USER"];
	PGResult *result;

	connection = [[PGConnection alloc] init];
	[connection setParameters:
	    [OFDictionary dictionaryWithKeysAndObjects: @"user", username,
							@"dbname", username,
							nil]];
	[connection connect];

	[connection executeCommand: @"DROP TABLE IF EXISTS test"];
	[connection executeCommand: @"CREATE TABLE test ("
				    @"    id integer,"
				    @"    name varchar(255),"
				    @"    content text,"
				    @"    success boolean"
				    @")"];
	[connection executeCommand: @"INSERT INTO test (id, name, content) "
				    @"VALUES ($1, $2, $3)"
			parameters: [OFNumber numberWithInt: 1], @"foo",
				    @"Hallo Welt!", nil];
	[connection executeCommand: @"INSERT INTO test (id, content, success) "
				    @"VALUES ($1, $2, $3)"
			parameters: [OFNumber numberWithInt: 2],
				    [OFNumber numberWithInt: 2],
				    [OFNumber numberWithBool: true], nil];
	[connection insertRow: [OFDictionary dictionaryWithKeysAndObjects:
				   @"content", @"Hallo!", @"name", @"foo", nil]
		    intoTable: @"test"];

	result = [connection executeCommand: @"SELECT * FROM test"];
	of_log(@"%@", result);
	of_log(@"JSON: %@", [result JSONRepresentation]);

	for (id row in result)
		for (id col in row)
			of_log(@"%@", col);

	result = [connection executeCommand: @"SELECT COUNT(*) FROM test"];
	of_log(@"%@", result);

	[OFApplication terminate];
}
@end
