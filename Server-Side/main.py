def scanit(request):
    from google.cloud import vision
    from google.cloud import storage
    from flask import Flask, request
    import numpy as np
    import math
    import json
    from shapely.geometry import Point
    from shapely.geometry.polygon import Polygon
    data = request.get_json()
    result = []
    selection = data.get("selection")
    vision_client = vision.ImageAnnotatorClient()
    length =  data.get("pages")
    file_name = data.get("file")
    storage_client = storage.Client()
    gcs_source_uri = r'?' + file_name
    gcs_destination_uri = r'?'.format(file_name)
    mime_type = 'application/pdf'

    # How many pages should be grouped into each json output file.
    batch_size = 100

    client = vision.ImageAnnotatorClient()

    feature = vision.Feature(
        type_=vision.Feature.Type.DOCUMENT_TEXT_DETECTION)

    gcs_source = vision.GcsSource(uri=gcs_source_uri)
    input_config = vision.InputConfig(
        gcs_source=gcs_source, mime_type=mime_type)

    gcs_destination = vision.GcsDestination(uri=gcs_destination_uri)
    output_config = vision.OutputConfig(
        gcs_destination=gcs_destination, batch_size=batch_size)

    async_request = vision.AsyncAnnotateFileRequest(
        features=[feature], input_config=input_config,
        output_config=output_config)

    operation = client.async_batch_annotate_files(
        requests=[async_request])

    print('Waiting for the operation to finish.')
    operation.result(timeout=420)
    
    def getlengths(textannotate):
        num = 0
        pages = []
        blocks = []
        paragraphs = []
        for page in textannotate['pages']:
            lilblock = []
            page_block_pg = []
            for block in pages['blocks']:
                lilparagraph = []
                pg_block = []
                for paragraph in block['paragraphs']:
                    num  += len(paragraph['words'])
                    lilparagraph.append(num)
                page_block_pg.append(lilparagraph)
                lilblock.append(num)
                pg_block.append(lilparagraph)
                blocks.append(lilblock)
            pages.append(num)
            blocks.append(lilblock)
            paragraphs.append(page_block_pg)
        return pages, blocks, paragraphs
    
    def getbounds(textannotate, pages, blocks, paragraphs, num):
        box = []
        page = np.searchsorted(np.array(pages), num)
        block = np.searchsorted(np.array(blocks[page]), num)
        paragraph = np.searchsorted(np.array(paragraphs[page][block]), num)
        subtract = 0
        if page > 0: 
            subtract += page
        if block > 0: 
            subtract += block
        if paragraph > 0: 
            subtract += paragraph 
        precision = num - subtract
        boundsish = textannotate['pages'][page]['blocks'][block]['paragraphs'][paragraph]['words'][precision]['bounding_box']['normalized_vertices']
        for point in boundsish:
            box.append([point['x'], point['y']])
        return box

    def getselection(textannotate, box):
        def dejson(vertices):
            new = []
            for item in vertices:
                new.append(item['x'], item['y'])
            return new
        border = Polygon(box)
        def check(thing):
            better = dejson(thing)
            point1 = np.mean(better)
            return border.contains(Point(point1))
        wordlist = []
        for page in textannotate['pages']:
            for block in page['blocks']:
                for paragraph in block['paragraph']:
                    for word in paragraph['words']:
                        wordlist.append(word)
        reallist = filter(check , wordlist)
        finallist = []
        for word in reallist:
            text = ''
            for symbol in word['symbols']:
                text += symbol['text']
            finallist.append(text)
        return finallist

    filesish = []
    files = []
    for x in range(math.ceil(pages/100)):
        if x >= pages/100:
            filesish.append(file_name + '/output' + (x * 100 + 1) + '-to-' + pages + '.json')
        else:
            filesish.append(file_name + '/output' + ((x + 1) * 100) + '-to-' + pages + '.json')
        
    bucket = storage_client.bucket(r'?')
    for jsonthing in filesish:
        jsonblob = bucket.blob(jsonthing) 
        jsonmem = json.download_as_string()
        files.push(json.loads(jsonmem))
    json1 = files[0]
    templatefull = json1['responses'][0]['fullTextAnnotation']
    templatetextish = templatefull['text']
    templatetext  = templatetextish.split( )
    temp1page, temp1block, temp1para = getlengths(templatefull)
    searchmatrixish = []
    for x in range(len(templatetext)):
        bounds = getbounds(templatefull, temp1page, temp1block, temp1para, x)
        got = {"word": templatetext[x], "bounds": bounds}
        searchmatrixish.append(got)

    searchmatrix = filter(lambda wd: templatetext.count(wd) == 1,searchmatrixish)
    
    for output in range(len(files)):
        for pageindex in range(len(output['responses'])):
            if output == 0 and pageindex == 0:
                continue
            page = files[output]['responses'][pageindex]['fullTextAnnotation']
            pagetextish = page['text']
            pagetext = pagetextish.split( )
            foundtext = []
            for word in templatetext:
                if word in pagetext and pagetext.count(word) == 1:
                    foundtext.append(word)
            if len(foundtext) >= 4:
                foundmatrix = []
                H = []
                page_page, page_block, page_para = getlengths(page)
                for item in foundtext:
                    index = pagetext.index(item)
                    bounds = getbounds(page, page_page, page_block, page_para, index)
                    foundmatrix.append({'word': item, 'bounds': bounds})
                    H.append([searchmatrix[searchmatrix.index(item)]['bounds'], bounds])
                
                homography = []
                for i in range(4):
                    homography.append([-np.mean(np.array(H[i][0]))[0][0], -np.mean(np.array(H[i][0]))[0][1], 1, 0, 0, 0, np.mean(np.array(H[i][0]))[0][0] * np.mean(np.array(H[i][1]))[0][0], np.mean(np.array(H[i][0]))[0][1] *  np.mean(np.array(H[i][1]))[0][0],  np.mean(np.array(H[i][1]))[0][0]])
                    homography.append([0, 0, 0, -np.mean(np.array(H[i][0]))[0][0], -np.mean(np.array(H[i][0]))[0][1], -1, np.mean(np.array(H[i][0]))[0][0] * np.mean(np.array(H[i][1]))[0][1], np.mean(np.array(H[i][0]))[0][1] *  np.mean(np.array(H[i][1]))[0][1], np.mean(np.array(H[i][1]))[0][1]])
                homography.append([0, 0, 0, 0, 0, 0, 0, 0, 1])
                outhomo = np.linalg.solve(homography, [0, 0, 0, 0, 0, 0, 0, 0, 1])[0]
                found = []
                for selector in selection:
                    goodhn = np.reshape(outhomo, (3, 3))
                    goodh = goodhn[0]
                    boundsb = []
                    for item in selector['bounds']:
                        boundsb,append(item[0], item[1], 1)
                    realboxn = np.dot(boundsb, goodh)
                    realbox = realboxn[0]
                    finishedbox = []
                    for item in realbox:
                        finishedbox.append[item[0], item[1]]
                    slick = getselection(page, finishedbox)
                    title = selector["title"]
                    got = {"title": title, "value": slick}
                    found.append(got)
                result.append(found)
    return json.dumps(result);          

