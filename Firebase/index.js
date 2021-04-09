const functions = require('firebase-functions');
const admin = require('firebase-admin');
const vision = require('@google-cloud/vision').v1;
const matrix = require('matrix-js/lib');
admin.initializeApp();
const path = require('path');
const {Storage} = require('@google-cloud/storage');
const fs = require('fs');
const os = require('os');
exports.scanner = functions.https.onCall(async(data, context) => {   
    console.log('Started')
    const storage = new Storage();
    var respnse = [];
    /*const searches = data.bounds;*/
    const fileName = data.file;
    const pages = data.pages
    var bucket = storage.bucket('testocr-1100.appspot.com');       
    var newbuck = storage.bucket('receiver-bucket-test')
    const client = new vision.ImageAnnotatorClient();
    var enrtybucket = 'testocr-1100.appspot.com';
    var exitbucket = 'receiver-bucket-test';
    const gcsSourceUri = `gs://${enrtybucket}/${fileName}`;
    const gcsDestinationUri = `gs://${exitbucket}/${fileName}/`;
    const inputConfig = {
        mimeType: 'application/pdf',
        gcsSource: {
        uri: gcsSourceUri,
        },
    };
    const outputConfig = {
    gcsDestination: {
        uri: gcsDestinationUri,
    },
    };
    const features = [{type: 'DOCUMENT_TEXT_DETECTION'}];
    const request = {
    requests: [
        {
        inputConfig: inputConfig,
        features: features,
        outputConfig: outputConfig,
        },
    ],
    };
    const [operation] = await client.asyncBatchAnnotateFiles(request);
    const [filesResponse] = await operation.promise();
    var filesStand  = [];
    var files = [];
    for(let i = 0; i < Math.ceil(pages/100); i++){
        if(pages - 100 < 100*i){
            console.log('Maan');
            filesStand.push(fileName + "/" + "output-" + (100*i + 1) +"-to-"+ pages +".json")
        }else{
            console.log('Maan');
            filesStand.push(fileName + "/" + "output-" + (100*i + 1) +"-to-"+ (100*(i + 1)) +".json")
        }}







        
    filesStand.forEach((filename) => {
        let tempFilePath = path.join(os.tmpdir(), filename);
         newbuck.file(filename).download( (err, contents) => {
            if(err === null){
                files.push(contents[0]);
                console.log(contents === null);
                console.log('Something"s coming');
                
             }
            else {
                console.log(err.message)
            }
            
        }
        );
         

    }); 


    console.log('Here');  
    return files.length; 
    /*var template = files[0].responses[0].responses[0].fullTextAnnotation;
    var maintext = template.text;
    basematrix = maintext.split('/n').split(' ');
    searchmatrix1 = basematrix.filter((sth) => {
        if(basematrix.indexOf(sth) === basematrix.lastIndexOf(sth)){
            return sth;
        }                    
    });     
    
    var bigBlock = getblocks(template.pages[0]);
    var searchmatrix = [];
    for(ej in searchmatrix1){
        let x = basematrix.indexOf(ej);
        let psd = 0;
        let block = 0;
        while(x > psd + bigBlock[block]){
            psd += bigBlock[block];
            block += 1;
        }
        let bounds = getpolybounds(template.blocks[block], x)
        searchmatrix.push({"word": ej,"bounds": bounds});
    } 
    files.responses[0].responses[0].shift();    
    for(x in files){
        for(let fr = 0; fr <= x.length; fr++){
            let res = x[fr].fullTextAnnotation;
            let blockers = getblocks(res.pages[0]);
            let currentmat = res.text.split('\n').split(' ');
            let transform = []
            for(word in searchmatrix){
                    if(word in currentmat && currentmat.indexOf(word) === currentmat.lastIndexOf(word)){
                        var x = currentmat.indexOf(word)
                        var psd = 0;
                        var block = 0;
                        while(x > psd + res.pages[0][block]){
                            psd += res.pages[0][block];
                            block += 1;
                        }
                        var bounds = getpolybounds(res.pages[0].blocks[block], x);
                        transform.push({"word": word,"bounds": bounds});
                    }
            }
            
            let resultant = matrix([0, 0, 0, 0, 0, 0, 0, 0, 1]);
            let arch = [];
            if(transform.length >= 4){
                for(let point = 0; point < 4; point++){
                    let p1 = [0, 0];
                    let P1 = matrix(p1);
                    let p2 = [0, 0];
                    let P2 = matrix(p2);
                    transform[point].bounds.forEach((bound) => {
                        P2.add([bound.x/4, bound.y/4]);
                    });
                    searchmatrix[point].bounds.forEach((bound) => {
                        P1.add([bound.x/4, bound.y/4]);
                    });
                    p1 = P1();
                    p2 = P2();
                    arch.push([p1, p2]);       
                 }
                var homography1 = [[-arch[0][0][0], -arch[0][0][1], -1 , 0 , 0 , 0, arch[0][0][0]*arch[0][1][0], arch[0][0][1]*arch[0][1][0], arch[0][1][0]], 
                [0 , 0, 0, -arch[0][0][0], -arch[0][0][1], -1, arch[0][0][0]*arch[0][1][1], arch[0][0][1]*arch[0][1][1], arch[0][1][1]], 
                [-arch[1][0][0], -arch[1][0][1], -1 , 0 , 0 , 0, arch[1][0][0]*arch[1][1][0], arch[1][0][1]*arch[1][1][0], arch[1][1][0]], 
                [0 , 0, 0, -arch[1][0][0], -arch[1][0][1], -1, arch[1][0][0]*arch[1][1][1], arch[1][0][1]*arch[1][1][1], arch[1][1][1]], 
                [-arch[2][0][0], -arch[2][0][1], -1 , 0 , 0 , 0, arch[2][0][0]*arch[2][1][0], arch[2][0][1]*arch[2][1][0], arch[2][1][0]], 
                [0 , 0, 0, -arch[2][0][0], -arch[2][0][1], -1, arch[2][0][0]*arch[2][1][1], arch[2][0][1]*arch[2][1][1], arch[2][1][1]], 
                [-arch[3][0][0], -arch[3][0][1], -1 , 0 , 0 , 0, arch[3][0][0]*arch[3][1][0], arch[3][0][1]*arch[3][1][0], arch[3][1][0]], 
                [0 , 0, 0, -arch[3][0][0], -arch[3][0][1], -1, arch[3][0][0]*arch[3][1][1], arch[3][0][1]*arch[3][1][1], arch[3][1][1]],
                [-arch[4][0][0], -arch[4][0][1], -1 , 0 , 0 , 0, arch[4][0][0]*arch[4][1][0], arch[4][0][1]*arch[4][1][0], arch[4][1][0]],
                [0 , 0, 0, -arch[4][0][0], -arch[4][0][1], -1, arch[4][0][0]*arch[4][1][1], arch[4][0][1]*arch[4][1][1], arch[4][1][1]], 
                [0, 0, 0, 0, 0, 0, 0, 0, 1]];
                let h = matrix(homography1);
                let H = resultant.div(h.inv());
                let homo2 = H();
                let homog = [[homo2[0], homo2[1], homo2[2]], [homo2[3], homo2[4], homo2[5]], [homo2[6], homo2[7], homo2[8]]];
                let homography = matrix(homog);
                let results = [];
    
                for(search in searches){
                    let newbounds = matrix();
                    search.bounds.forEach((el) =>
                    {newbounds.merge([el.x, el.y, 1])});
                    let newestbound = [];
                    newbounds.forEach((el) => 
                    {let rap = el.prod(homography);
                        newestbound.push(rap([1, 2]));
                    });
                    let p1 = matrix([0, 0]);
                    newestbound.forEach((b, index) => {
                        pl.add(matrix([b.bounds[index][0]/4, b.bounds[index][1]/4 ]));
                    });
                    let block, paragraph, words = findbounds(res.pages[0], p1(), newestbound);
                    let out = genwords(block, paragraph, words, currentmat, blockers, res.page[0]);
                    respnse.push({"title": search.title, "selection": out});
                }}
            }
    }
        
    return respnse;       

        
    function findbounds(page, bounds, blockers) {
        let blockfound = false;
        let block = 0;
        while(blockfound !== true){
            let box = page.blocks[block].boundingbox.normalizedVertices;
            
            if(bounds.x < box[0].x && bounds.x < box[1].x && bounds.x > box[2].x && bounds.x > box[3].x && bounds.y < box[0].y && bounds.y < box[1].y && bounds.y > box[2].y && bounds.y > box[3].y){
                blockfound = true;
            }
            else{
                block+=1
            }
        }
        let pgfound = false;
        let pg = 0;
        while(pgfound !== true){
            let box = page.blocks[block].paragraphs[pg];
            if(bounds.x < box[0].x && bounds.x < box[1].x && bounds.x > box[2].x && bounds.x > box[3].x && bounds.y < box[0].y && bounds.y < box[1].y && bounds.y > box[2].y && bounds.y > box[3].y){
                pgfound = true;
            }
            else{
                pg+=1
            }
        }
    let words = page.blocks[block].paragraphs[pg].words.filter((elemnt) => {
        return elemnt.boundingbox.normalizedVertices[0].x >= blockers[0].x && elemnt.boundingbox.normalizedVertices[1].x <= blockers[1].x && elemnt.boundingbox.normalizedVertices[2].x >= blockers[2].x && elemnt.boundingbox.normalizedVertices[3].x <= blockers[3].x && elemnt.boundingbox.normalizedVertices[0].y <= blockers[0].y && elemnt.boundingbox.normalizedVertices[1].y <= blockers[1].y && elemnt.boundingbox.normalizedVertices[2].y >= blockers[2].y && elemnt.boundingbox.normalizedVertices[3].y >= blockers[3].y
    });
    let matches = [];
    words.forEach((word) => {
        matches.push(page.blocks[block].paragraphs[pg].words.indexOf(word));
    });
    return block, pg, matches;
    }
    function genwords(block, parag, words, ref, refblock, page){
        let word = ''
        let location = 0;
        if(block > 0){
            location += refblock.slice(0 ,block).reduce((a, b) => {
                return a + b;
            });
        }
        for(let i = 0; i < parag; i++){
            location += page.blocks[block].paragraphs[parag].words.length;
        }
        words.forEach((wd) => {
            word += ref[wd + location];
        });
            return word;}
        function getblocks(page){
            let bracks = [];
            page.blocks.forEach((block) => {
                var len = 0;
                block.paragraphs.forEach((paragraph) => {
                    len += paragraph.words.length 
                });
                brack.push(len);
            });
            return bracks;
        }*/
    });


exports.scans = functions.auth.user().onCreate(async(user) => {
    await admin.database().ref("users").child(user.uid).set({
        scans: 0,});
    console.log('Registered ' + user.displayname + '\n @' + user.email + '\n UID: ' + user.uid);
});

exports.delscans = functions.auth.user().onDelete(async(user) => {
    await admin.database().db.ref('users').child(user.uid).remove();
    console.log('Deregistered ' + user.displayname + '\n @' + user.email + '\n UID: ' + user.uid);
});

exports.helloWorld = functions.https.onCall((data, context) => {
    const text = data.text;
    
    const uid = context.auth.uid;
    const name = context.auth.token.name || null;
    const email = context.auth.token.email || null;
    return {
        text: text,
        uid: uid,
        name: name,
        email: email
    };
});

