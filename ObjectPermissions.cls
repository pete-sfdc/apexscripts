// list the objects you want to evaluate (can be any object)
List<String> CustomObjects = new List<String>{
    'Account',
    'Opportunity',
    'Some_Custom_Object__c'
};

// This commented bit is a more automated approach

/*
Schema.DescribeSObjectResult dr;

for(Schema.SObjectType objType:Schema.getGlobalDescribe().values()) {
    dr = objType.getDescribe();
    if(dr.isCustom() && !dr.getName().replace('__c','').contains('__')) {
        CustomObjects.add(dr.getName());
    }
}
*/

// list the emails you want the results to be sent to
List<String> toAddresses = new List<String> {
    'someone@example.com'
};

String header = 'PermSet Id,Object,User';
List<String> results = new List<String>{header};
String delimiter = ',';

for(PermissionSet ps: [
    SELECT  Id, (
                SELECT  SObjectType
                FROM    ObjectPerms
                WHERE   SObjectType IN:CustomObjects
                AND     PermissionsRead = true
            ), (
                SELECT  Assignee.Name
                FROM    Assignments
            )
    FROM    PermissionSet 
    WHERE   Id IN (
        SELECT  ParentId 
        FROM    ObjectPermissions 
        WHERE   SObjectType IN:CustomObjects 
        AND     PermissionsRead = true
    ) 
    AND     Id IN (
        SELECT  PermissionSetId 
        FROM    PermissionSetAssignment
    )
]) {
    for(ObjectPermissions o:ps.ObjectPerms) {
        for(PermissionSetAssignment psa:ps.Assignments) {
            results.add(ps.id+delimiter+o.SObjectType+delimiter+psa.Assignee.Name);
        }
    }
}

Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
Blob csvBlob = Blob.valueOf(String.join(results,'\n'));
String csvname = 'PermSet.csv';
csvAttc.setFileName(csvname);
csvAttc.setBody(csvBlob);

Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
String subject = 'Object Permissions CSV';
email.setSubject( subject );
email.setToAddresses( toAddresses );
email.setPlainTextBody( 'Object Permissions CSV ' );
email.setFileAttachments(
    new Messaging.EmailFileAttachment[]{csvAttc}
);

List<Messaging.SendEmailResult> r = Messaging.sendEmail(
    new Messaging.SingleEmailMessage[] {email}
);
