/**
 * This JS file is used to generate word docs for different functionalities
 * MultiBioDoc - Generate Bio / Generate Short Bio from 'Generate Bio' tab / list page
 * ContactBioDoc - Generate Bio from 'Generate Bio' button from Cotact Record Object
 * ContactOrgBioDoc - To generate Donor Memo
 */
var createdByUser, createdDate;
const font = 'Times New Roman';
function createDoc(bioHeader, createdByUser, createdDate, retURL, shortListId, docType, listName, contactData) {
    this.createdByUser = createdByUser;
    this.createdDate =  createdDate;
    switch (docType) {
        case 'MultiBioDoc': MultiBioDoc(bioHeader, createdByUser, createdDate, retURL, shortListId, listName, contactData);break;
        case 'MailingTempalteDoc': MailingTempalteDoc(bioHeader, createdByUser, createdDate, retURL, shortListId, contactData);break;
        case 'ContactBioDoc': ContactBioDoc(bioHeader, createdByUser, createdDate, retURL, shortListId, contactData);break;
        case 'ContactOrgBioDoc': DonorMemoReport(contactData, retURL);break;
    }
}

function MultiBioDoc(bioHeader, createdByUser, createdDate, retURL, shortListId, listName, contactData ) {
	const doc = new docx.Document();
    let conts = JSON.parse(contactData);
    let items =[];
    let rows =[];
	let sourceSelected = false;

    // Step 1: Group contacts by sourceName
    const groupedContacts = {};
    conts.forEach(contact => {
        const src = contact.sourceName && contact.sourceName.trim() !== '' ? contact.sourceName : 'No Source';
        if(contact.sourceName && contact.sourceName.trim() !== ''){
            sourceSelected = true;
        }
        if (!groupedContacts[src]) {
            groupedContacts[src] = [];
        }
        groupedContacts[src].push(contact);
    });

    // Step 2: Loop over each group (sorted: sources first, then No Source last)
    const orderedSources = Object.keys(groupedContacts).sort((a, b) => {
        if (a === 'No Source' || a ==='Remaining Contacts') return 1;
        if (b === 'No Source' || b ==='Remaining Contacts') return -1;
        return a.localeCompare(b);
    });

    orderedSources.forEach(sourceName => {
        // --- HEADER ROW FOR SOURCE NAME ---
        if(sourceSelected){
        let headername = sourceName == 'No Source' ? '' : sourceName;
        const headerRow = new docx.TableRow({
            children: [
                new docx.TableCell({
                    children: [new docx.Paragraph({
                        children: [new docx.TextRun({
                            text: headername + ' ('+groupedContacts[sourceName].length+')',
                            bold: true,
                            font: font,
                            size: 28
                        })],
                        alignment: docx.AlignmentType.LEFT,
                        spacing: { after: 50 }
                    })],
                    columnSpan: 2, // merge both columns
                    verticalAlign: docx.VerticalAlign.CENTER,
                    shading: { fill: '#DAE9F7' }, // light gray background
                    margins: { top: 20, bottom: 10, left: 100, right: 100 }
                })
            ]
        });
        rows.push(headerRow);
    }

	// --- CONTACTS UNDER THIS SOURCE ---
	groupedContacts[sourceName].forEach(x => {
        let tmpImg = '';
        if( x.img ) {
            tmpImg = docx.Media.addImage(doc, Uint8Array.from(atob(x.img), c => c.charCodeAt(0)));
        }

        let fullTitle = '';

        if (x.singleTitle) {
            fullTitle += x.singleTitle;
        }

        if (x.accountName) {
            fullTitle += (fullTitle ? ', ' : '') + x.accountName;
        }

        let content = [new docx.Paragraph({children: [new docx.TextRun({ text: x.name, bold: true, font: font, size:24})]})];
        if(fullTitle !== '') {
            content.push(new docx.Paragraph({children: [new docx.TextRun({text: fullTitle, bold: true, font: font, size:24})]}));
        }
        
        content.push(new docx.Paragraph({text:""}));

        if( x.confidentialNots ) {
            content.push(new docx.Paragraph({children: [new docx.TextRun({ text: "Confidential Notes:", color:"red", font: font, size:24 })], spacing:{after:100}}));
            let note = x.confidentialNots;
            
            note.split('\r').forEach(singleContent => {
                if( singleContent !== '\r' ) {
                    singleContent = singleContent.trim();
                    content.push(new docx.Paragraph({children: [new docx.TextRun({ text: singleContent, color:"red", font: font, size:24})]}));
                }
            });
            content.push(new docx.Paragraph({text:""}));
        }

        if( x.interactions ) {
            content.push(new docx.Paragraph({children: [new docx.TextRun({ text: "Interaction(s):", bold: true, font: font, size:24 })], spacing:{after:100}}));
            x.interactions.forEach(y => {
                let interactionContent = '';
                let interactionDate = y.interactionDate;
                if(interactionDate !== null) {
                    interactionContent+=interactionDate;
                }
                if(y.interaction.Name !== null) {
                    if(interactionContent !== '') {
                        interactionContent+=', ';
                    }
                    interactionContent += y.interaction.Name;
                }

                if(y.interactionBackground !== '') {
                    if(interactionContent !== '') {
                        interactionContent+=', ';
                    }
                    interactionContent += y.interactionBackground;
                }
                content.push(new docx.Paragraph({children: [new docx.TextRun({ text: interactionContent, font: font, size:24})]}));
				content.push(new docx.Paragraph({text:""}));
            });
            
        }

        if( x.events ) {
            content.push(new docx.Paragraph({children: [new docx.TextRun({ text: "Event(s):", bold: true, font: font, size:24 })], spacing:{after:100}}));
            x.events.forEach(y => {
                let eventContent = '';
                if(y.eventDate !== null) {
                    eventContent += y.eventDate;
                }
                if(y.eventSubject !== null) {
                    if(eventContent !== '') {
                        eventContent+=', ';
                    }
                    eventContent+=y.eventSubject;
                }
                content.push(new docx.Paragraph({children: [new docx.TextRun({ text: eventContent, font: font, size:24})]}));
            });
            content.push(new docx.Paragraph({text:""}));
        }
        
        if( x.description ) {
            let bio = x.description;
            content.push(new docx.Paragraph({children: [new docx.TextRun({ text: bioHeader, bold: true, font: font, size:24 })], spacing:{after:100}}));
            bio.split('\r').forEach(singleContent => {
                if( singleContent !== '\r' ) {
                    singleContent = singleContent.trim();
                    content.push(new docx.Paragraph({children: [new docx.TextRun({ text: singleContent, font: font, size:24 })]}));
                }
            });

        }

        let cellWith1 = {size:30, type:docx.WidthType.PCT};
        let rowCell1 = new docx.TableCell({children: [new docx.Paragraph(tmpImg)],width: cellWith1, verticalAlign: docx.VerticalAlign.CENTER, margins: {top: 100, bottom: 100, left: 100,right: 100}});

        let cellWith2 = {size:70, type:docx.WidthType.PCT};
        let rowCell2 = new docx.TableCell({children: content, width: cellWith2, verticalAlign: docx.VerticalAlign.CENTER, margins: {top: 100, bottom: 100, left: 100,right: 100}});
        let row = new docx.TableRow({children: [rowCell1, rowCell2],});

        rows.push(row);
    });
    });
    
    const table = new docx.Table({
        rows: rows,
    });

    doc.addSection({
        headers: {
                default: new docx.Header({
                    children: [new docx.Paragraph({
                        alignment: docx.AlignmentType.LEFT,
                        children: [
                            new docx.TextRun({text: listName, bold: true, font: font, size:24}),
                        ],
                    })],
                }),
            },
        footers: pageFooter(),
        children: [table],
    });
    let fileName = "Multi-Contact Bio Report"
    if(bioHeader == 'Short Bio:'){
        fileName = "Multi-Contact Short Bio Report";
    }
    if( shortListId ) {
        fileName += " - "+ shortListId +".docx";
    }else{
        fileName += ".docx";
    }

    saveFile(fileName ,retURL , doc);
}
function MailingTempalteDoc(bioHeader, createdByUser, createdDate, retURL, shortListId, contactData ) {
	const doc = new docx.Document();
    let rows =[];
    let conts = JSON.parse(contactData);
    let content = [];
    
    conts.forEach(x => {
    	//Generate current date info
    	var today = new Date();
		var dd = String(today.getDate()).padStart(2, '0');
		var mm = today.toLocaleString('default', { month: 'long' });
		var yyyy = today.getFullYear();

		let  currentDate = mm + ' ' + dd + ', ' + yyyy;

        content.push(new docx.Paragraph({text: currentDate}));
    	content.push(new docx.Paragraph({text: ""}));
    	content.push(new docx.Paragraph({text: x.name}));
    	content.push(new docx.Paragraph({text: x.singleTitle}));
        content.push(new docx.Paragraph({text: x.accountName, spacing:{after:300}}));
    	
    	content.push(new docx.Paragraph({text: ""}));
    	content.push(new docx.Paragraph({text: "Dear: "}));
    	content.push(new docx.Paragraph({text: ""}));
    	content.push(new docx.Paragraph({text: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.", margins:{right:200}}));
    	content.push(new docx.Paragraph({text: ""}));
    	content.push(new docx.Paragraph({text: "Aliquet nibh praesent tristique magna sit amet. Magna ac placerat vestibulum lectus mauris ultrices eros in cursus. Vehicula ipsum a arcu cursus vitae."}));
    	content.push(new docx.Paragraph({text: ""}));
    	content.push(new docx.Paragraph({text: "Ridiculus mus mauris vitae ultricies leo integer."}));
    	content.push(new docx.Paragraph({text: "", spacing:{after:200}}));
    	content.push(new docx.Paragraph({text: "Best,"}));
    	content.push(new docx.Paragraph({text: ""}));
    	content.push(new docx.Paragraph({children: [new docx.TextRun("Patricia E. Harris"), new docx.PageBreak()]}));
    });

    doc.addSection({
		children: content,
    });
    saveFile("Annual Report - "+shortListId+".docx" ,retURL , doc);
}

function ContactBioDoc(bioHeader, createdByUser, createdDate, retURL, shortListId, contactData ) {
    const doc = new docx.Document();
    let conts = JSON.parse(contactData);
    let items =[];
    let rows =[];
    let contact = conts[0];
    
    let tmpImg = '';
    if( contact.img ) {
        tmpImg = docx.Media.addImage(doc, Uint8Array.from(atob(contact.img), c => c.charCodeAt(0)));
    }

    let fullTitle = '';

    if (contact.singleTitle) {
        fullTitle += contact.singleTitle;
    }

    if (contact.accountName) {
        fullTitle += (fullTitle ? ', ' : '') + contact.accountName;
    }

    let content = [new docx.Paragraph({children: [new docx.TextRun({ text: contact.name, bold: true, font: font, size:24})]})];
    if(fullTitle !== '') {
        content.push(new docx.Paragraph({children: [new docx.TextRun({text: fullTitle, bold: true, font: font, size:24})]}));
    }

    content.push(new docx.Paragraph({text:""}));

    if( contact.confidentialNots ) {
        content.push(new docx.Paragraph({children: [new docx.TextRun({ text: "Confidential Notes:", color:"red", font: font, size:24  })], spacing:{after:100}}));
        let note = contact.confidentialNots;
        
        note.split('\r').forEach(singleContent => {
            if( singleContent !== '\r' ) {
                singleContent = singleContent.trim();
                content.push(new docx.Paragraph({children: [new docx.TextRun({ text: singleContent, color:"red", font: font, size:24 })]}));
            }
        });

        content.push(new docx.Paragraph({text:""}));
    }
    
    if( contact.interactions ) {
        content.push(new docx.Paragraph({children: [new docx.TextRun({ text: "Interaction(s):", bold: true, font: font, size:24 })], spacing:{after:100}}));
        contact.interactions.forEach(x => {
            let interactionContent = '';
            let interactionDate = x.interactionDate;
            if(interactionDate !== null) {
                interactionContent+=interactionDate;
            }
            if(x.interaction.Name !== null) {
                if(interactionContent !== '') {
                    interactionContent+=', ';
                }
                interactionContent += x.interaction.Name;
            }

            if(x.interactionBackground !== '') {
                if(interactionContent !== '') {
                    interactionContent+=', ';
                }
                interactionContent += x.interactionBackground;
            }
            
            content.push(new docx.Paragraph({children: [new docx.TextRun({ text: interactionContent, font: font, size:24})]}));
			content.push(new docx.Paragraph({text:""}));
        });
        
    }

    if( contact.events ) {
        content.push(new docx.Paragraph({children: [new docx.TextRun({ text: "Event(s):", bold: true, font: font, size:24 })], spacing:{after:100}}));
        contact.events.forEach(y => {
            let eventContent = '';
            if(y.eventDate !== null) {
                eventContent += y.eventDate;
            }
            if(y.eventSubject !== null) {
                if(eventContent !== '') {
                    eventContent+=', ';
                }
                eventContent += y.eventSubject;
            }

            content.push(new docx.Paragraph({children: [new docx.TextRun({ text: eventContent, font: font, size:24})]}));
        });
        content.push(new docx.Paragraph({text:""}));
    }

    if( contact.description ) {
        let bio = contact.description;
        content.push(new docx.Paragraph({children: [new docx.TextRun({ text: bioHeader, bold: true, font: font, size:24 })], spacing:{after:100}}));
        bio.split('\r').forEach(singleContent => {
            if( singleContent !== '\r' ) {
                singleContent = singleContent.trim();
                content.push(new docx.Paragraph({children: [new docx.TextRun({ text: singleContent, font: font, size:24})]}));
            }
        });

    }
    let cellWith1 = {size:30, type:docx.WidthType.PCT};
    let rowCell1 = new docx.TableCell({children: [new docx.Paragraph(tmpImg)],width: cellWith1, verticalAlign: docx.VerticalAlign.CENTER, margins: {top: 100, bottom: 100, left: 100,right: 100}});

    let cellWith2 = {size:70, type:docx.WidthType.PCT};
    let rowCell2 = new docx.TableCell({children: content, width: cellWith2, verticalAlign: docx.VerticalAlign.CENTER, margins: {top: 100, bottom: 100, left: 100,right: 100}});
    let row = new docx.TableRow({children: [rowCell1, rowCell2]});

    rows.push(row);


    const table = new docx.Table({
        rows: rows,
    });

    doc.addSection({
        headers: {
            default: new docx.Header({
                children: [new docx.Paragraph({children: [new docx.TextRun({ text: "Contact Bio Report", font: font, size:18  })]})],
            }),
        },
        footers: pageFooter(),
        children: [table],
    });
    saveFile("Contact Bio Report - "+contact.name+".docx" ,retURL , doc);
}


function DonorMemoReport(data, retURL) {
    let allData = JSON.parse(data);
    console.log ('allData :::::: '+JSON.stringify(allData));
    console.log ('selectedFilters :::::: '+JSON.stringify(allData.selectedFilters));
    let doc;

    if (allData.selectedFilters.sortBy === 'Focus Area') {
        doc = getFocusAreasWithDonors(allData);
    } else if (allData.selectedFilters.sortBy === 'Donor') {
        doc = getDonors (allData);
    } else if (allData.selectedFilters.sortBy === 'Project') {
        doc = getDonorsByProject (allData);
    }

    saveFile("Fundraising Memo Report.docx" , retURL , doc);
}

function addCoverPage(allData, content) {
    let allCoverPageDonors = allData.coverPageSection.donors;
    let tmpCoverPageDonors = [];
    let header = 'Gifts $10,000 and above received in ' + allData.coverPageTimeFrame;
    let noDataHeader = 'No gifts received in ' + allData.coverPageTimeFrame;
    content.push(new docx.Paragraph({ text: "" }));

    if (allData.coverPageSection.hasData) {
        let grandTotal = 0;
        allCoverPageDonors.forEach(x => {
            let total = 0;
            let projects = [];
            x.projects.forEach(y => {
                let rAmount = roundAmount(y.amountI);
                if (rAmount.roundedAmount >= 10000) {
                    total += rAmount.roundedAmount;
                    projects.push(y);
                    grandTotal += rAmount.roundedAmount;
                }
            });
            x.amountInteger = total;
            x.projects = projects;
            tmpCoverPageDonors.push(x);
        });

        const formattedGrandTotal = roundAmount(grandTotal).formattedAmount;
        header += ` (Total: $${formattedGrandTotal})`;

        content.push(new docx.Paragraph({
            alignment: docx.AlignmentType.LEFT,
            children: [new docx.TextRun({ text: header, font: font, size: 32, color: '#2f5496' })]
        }));
        tmpCoverPageDonors.forEach(x => {
            if (x.donorName != '#') {
                content.push(new docx.Paragraph({ text: "" }));
                content.push(new docx.Paragraph({ text: "" }));
                x.totalAmount = '$' + roundAmount(x.amountInteger).formattedAmount;
                let donorHeader = x.donorName + ' - ' + x.totalAmount + ' for:';
                if (x.amountInteger > 0) {
                    content.push(new docx.Paragraph({
                        children: [new docx.TextRun({ text: donorHeader, bold: true, font: font, size: 24 })]
                    }));
                }
                x.projects.forEach(y => renderProjectWithBreakout(content, y, 0, true));
            }
        });
    } else {
        content.push(new docx.Paragraph({
            alignment: docx.AlignmentType.LEFT,
            children: [new docx.TextRun({ text: noDataHeader, font: font, size: 36, color: '#2f5496' })]
        }));
    }

    content.push(new docx.Paragraph({ children: [new docx.TextRun(""), new docx.PageBreak()] }));
    return content;
}

function getDonors(allData) {
    let allDonors = allData.mainPageSection.donors;
    const doc = new docx.Document();
    let content = [];
    let header1 = 'Fundraising Partnerships Report';
    let header6 = `Top Donors Total Giving - $${allData.selectedFilters.minDonorAmount.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",")} and above`;

    content.push(new docx.Paragraph({
        alignment: docx.AlignmentType.LEFT,
        children: [new docx.TextRun({ text: header1, bold: true, font: font, size: 50 })]
    }));

    if (allData.selectedFilters.includeCoverPage) {
        content = addCoverPage(allData, content);
    }

    content.push(new docx.Paragraph({
        alignment: docx.AlignmentType.LEFT,
        children: [new docx.TextRun({ text: header6, font: font, size: 36, color: '#00B050' })]
    }));

    let tmpDonors = [];
    let grandTotal = 0;
    allDonors.forEach(x => {
        let total = 0;
        let projects = [];
        x.projects.forEach(y => {
            let rAmount = roundAmount(y.amountI);
            total += rAmount.roundedAmount;
            projects.push(y);
        });
        x.amountInteger = total;
        x.projects = projects;
        tmpDonors.push(x);
        grandTotal += total;
    });

    let formattedGrandTotal = roundAmount(grandTotal).formattedAmount;
    content.push(new docx.Paragraph({
        alignment: docx.AlignmentType.LEFT,
        children: [new docx.TextRun({ text: `Total: $${formattedGrandTotal}`, bold: true, font: font, size: 28 })]
    }));
    content.push(new docx.Paragraph({ text: "" }));

    tmpDonors.forEach(x => {
        if (x.donorName != '#') {
            content.push(new docx.Paragraph({ text: "" }));
            content.push(new docx.Paragraph({ text: "" }));
            x.totalAmount = '$' + roundAmount(x.amountInteger).formattedAmount;
            let donorHeader = x.donorName + ' - ' + x.totalAmount + ' for:';
            if (x.amountInteger > 0) {
                content.push(new docx.Paragraph({
                    children: [new docx.TextRun({ text: donorHeader, bold: true, font: font, size: 24 })]
                }));
            }
            x.projects.forEach(y => renderProjectWithBreakout(content, y, 0));
        }
    });

    doc.addSection({
        headers: { default: new docx.Header({ children: [] }) },
        footers: pageFooter(),
        children: content,
    });

    return doc;
}

function getFocusAreasWithDonors(allData) {
    let allFocusAreas = allData.mainPageSection.focusAreasWithDonors;
    const doc = new docx.Document();
    let content = [];
    let header1 = 'Fundraising Partnerships Report';
    let header6 = `Top Donors Total Giving - $${allData.selectedFilters.minDonorAmount.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",")} and above`;
    content.push(new docx.Paragraph({
        alignment: docx.AlignmentType.LEFT,
        children: [new docx.TextRun({ text: header1, bold: true, font: font, size: 50 })]
    }));
    if (allData.selectedFilters.includeCoverPage) {
        content = addCoverPage(allData, content);
    }
    content.push(new docx.Paragraph({
        alignment: docx.AlignmentType.LEFT,
        children: [new docx.TextRun({ text: header6, font: font, size: 36, color: '#00B050' })]
    }));
    let grandTotal = 0;
    allFocusAreas.forEach(f => {
        (f.donors || []).forEach(x => {
            (x.projects || []).forEach(y => {
                let rAmount = roundAmount(y.amountI);
                grandTotal += rAmount.roundedAmount;
            });
        });
    });
    const formattedGrandTotal = roundAmount(grandTotal).formattedAmount;

    content.push(new docx.Paragraph({
        alignment: docx.AlignmentType.LEFT,
        children: [new docx.TextRun({ text: `Total: $${formattedGrandTotal}`, bold: true, font: font, size: 28 })]
    }));
    content.push(new docx.Paragraph({ text: "" }));
    allFocusAreas.forEach(f => {
        let allDonors = f.donors || [];
        let tmpDonors = [];
        let focusAreaTotal = 0;
        allDonors.forEach(x => {
            let total = 0;
            let projects = [];
            (x.projects || []).forEach(y => {
                let rAmount = roundAmount(y.amountI);
                total += rAmount.roundedAmount;
                projects.push(y);
            });
            x.amountInteger = total;
            x.projects = projects;
            tmpDonors.push(x);
            focusAreaTotal += total;
        });
        const formattedFocusAreaTotal = roundAmount(focusAreaTotal).formattedAmount;
        content.push(new docx.Paragraph({ text: "" }));
        content.push(new docx.Paragraph({
            children: [new docx.TextRun({ text: `${f.focusArea} - $${formattedFocusAreaTotal} for:`, bold: true, font: font, size: 30 })]
        }));
        tmpDonors.forEach(x => {
            if (x.donorName == '#') return;
            content.push(new docx.Paragraph({ text: "" }));
            x.totalAmount = '$' + roundAmount(x.amountInteger).formattedAmount;
            let donorHeader = x.donorName + ' - ' + x.totalAmount + ' for:';
            content.push(new docx.Paragraph({
                bullet: { level: 0 },
                children: [new docx.TextRun({ text: donorHeader, bold: true, font: font, size: 24 })]
            }));
            (x.projects || []).forEach(y => renderProjectWithBreakout(content, y, 1));
        });
        content.push(new docx.Paragraph({ text: "" }));
    });
    doc.addSection({
        headers: { default: new docx.Header({ children: [] }) },
        footers: pageFooter(),
        children: content,
    });
    return doc;
}


function getDonorsByProject(allData) {
    let allProjects = allData.mainPageSection.projectsWithDonors;
    const doc = new docx.Document();
    let content = [];
    let header1 = 'Fundraising Partnerships Report';
    let header6 = `Top Donors Total Giving - $${allData.selectedFilters.minDonorAmount.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",")} and above`;

    content.push(
        new docx.Paragraph({
            alignment: docx.AlignmentType.LEFT,
            children: [new docx.TextRun({ text: header1, bold: true, font: font, size: 50 })]
        })
    );

    if (allData.selectedFilters.includeCoverPage) {
        content = addCoverPage(allData, content);
    }

    content.push(
        new docx.Paragraph({
            alignment: docx.AlignmentType.LEFT,
            children: [new docx.TextRun({ text: header6, font: font, size: 36, color: '#00B050' })]
        })
    );

    let grandTotal = 0;
    allProjects.forEach(p => {
        p.donors.forEach(x => {
            let rAmount = roundAmount(x.totalAmount);
            if (rAmount.roundedAmount >= allData.selectedFilters.minDonorAmount) {
                grandTotal += rAmount.roundedAmount;
            }
        });
    });

    let formattedGrandTotal = roundAmount(grandTotal).formattedAmount;

    content.push(
        new docx.Paragraph({
            alignment: docx.AlignmentType.LEFT,
            children: [new docx.TextRun({ text: `Total: $${formattedGrandTotal}`, bold: true, font: font, size: 28 })]
        })
    );
    content.push(new docx.Paragraph({ text: "" }));

    allProjects.forEach(p => {
        let tmpDonors = [];
        let projectTotal = 0;

        p.donors.forEach(x => {
            let rAmount = roundAmount(x.totalAmount);
            if (rAmount.roundedAmount >= allData.selectedFilters.minDonorAmount) {
                tmpDonors.push(x);
                projectTotal += rAmount.roundedAmount;
            }
        });

        let formattedProjectTotal = roundAmount(projectTotal).formattedAmount;

        content.push(new docx.Paragraph({ text: "" }));
        content.push(
            new docx.Paragraph({
                children: [
                    new docx.TextRun({ text: `${p.projectName} - $${formattedProjectTotal} for:`, bold: true, font: font, size: 24 }),
                ]
            })
        );

        tmpDonors.forEach(x => {
            if (x.donorName == '#') return;
            const openTotal = roundAmount(x.nonAnonAmount || 0).roundedAmount;
            const anonTotal = roundAmount(x.anonAmount  || 0).roundedAmount;
            const isMixed = openTotal > 0 && anonTotal > 0;
            let donorHeader = `${x.donorName} - ($${roundAmount(x.totalAmount).formattedAmount}) (${x.timeFrame})`;
            if (!isMixed && x.anonymous) donorHeader += ' (Anonymous)';
            content.push(new docx.Paragraph({
                bullet: { level: 0 },
                children: [new docx.TextRun({ text: donorHeader, font: font, size: 24 })]
            }));
            if (isMixed) {
                [
                    { amount: openTotal, years: x.nonAnonTimeFrame, anon: false },
                    { amount: anonTotal, years: x.anonTimeFrame,    anon: true  }
                ]
                .sort((a, b) => b.amount - a.amount)
                .forEach(sb => {
                    let text = `$${roundAmount(sb.amount).formattedAmount} (${sb.years})`;
                    if (sb.anon) text += ' (Anonymous)';
                    content.push(new docx.Paragraph({
                        bullet: { level: 1 },
                        children: [new docx.TextRun({ text: text, font: font, size: 24 })]
                    }));
                });
            }
        });
        content.push(new docx.Paragraph({ text: "" }));
    });

    doc.addSection({
        headers: { default: new docx.Header({ children: [] }) },
        footers: pageFooter(),
        children: content,
    });

    return doc;
}
    
const THOUSAND = 1e3;
const MILLION  = 1e6;
const BILLION  = 1e9;
const TRILLION = 1e12;

// ---------- Generic utilities (standalone, not nested) ----------
function roundHalfUp(n, decimals = 0) {
    const m = 10 ** decimals;
    // true HALF_UP (away from zero) for .5 cases (handles negatives too)
    return (n >= 0 ? Math.round(n * m) : -Math.round(-n * m)) / m;
}

function trimZeros(n, decimals) {
    // n is already rounded; toFixed is just for formatting
    let s = n.toFixed(decimals);
    return s.replace(/\.0+$|(\.\d*[1-9])0+$/, '$1');
}

function formatInt(n) {
    return Number(n).toLocaleString('en-US');
}

function mulAndRound0(a, b) {
    return Number((a * b).toFixed(0));
}

// ---------- Small-amount rule (≤ 9,499): ones/tens/hundreds ----------
function roundUnder9499(x) {
    const amount = { roundedAmount: 0, formattedAmount: '' };
    const absX = Math.abs(Number(x) || 0);
    let r;
    if(absX < 10) {
        r = roundHalfUp(x);
    } else if(absX < 100) {
        r = roundHalfUp(x / 10) * 10;
    } else {
        r = roundHalfUp(x / 100) * 100;
    }
    amount.roundedAmount = r;
    // Display: plain number under 1,000; else show K with one decimal
    if(Math.abs(r) >= THOUSAND) {
        const k = roundHalfUp(r / THOUSAND, 1);
        amount.formattedAmount = `${trimZeros(k, 1)}k`;
    } else {
        amount.formattedAmount = formatInt(r);
    }
    return amount;
}

// ---------- Unit-specific large rounding (K / M / B / T) ----------
function roundToK(x) {
    const scaled = roundHalfUp(x / THOUSAND);       // 0 decimals
    return {
        roundedAmount: mulAndRound0(scaled, THOUSAND),
        formattedAmount: `${trimZeros(scaled, 0)}k`,
    };
}

function roundToM(x) {
    const scaled = roundHalfUp(x / MILLION, 1);     // 1 decimal
    return {
        roundedAmount: mulAndRound0(scaled, MILLION),
        formattedAmount: `${trimZeros(scaled, 1)}M`,
    };
}

function roundToB(x) {
    const scaled = roundHalfUp(x / BILLION, 2);     // 2 decimals
    return {
        roundedAmount: mulAndRound0(scaled, BILLION),
        formattedAmount: `${trimZeros(scaled, 2)}B`,
    };
}

function roundToT(x) {
    const scaled = roundHalfUp(x / TRILLION, 2);    // 2 decimals
    return {
        roundedAmount: mulAndRound0(scaled, TRILLION),
        formattedAmount: `${trimZeros(scaled, 2)}T`,
    };
}

function roundOver9499(x) {
    const absX = Math.abs(Number(x) || 0);
    if(absX < MILLION) return roundToK(x);
    if(absX < BILLION) return roundToM(x);
    if(absX < TRILLION) return roundToB(x);
    return roundToT(x);
}

function roundAmount(x) {
    const absX = Math.abs(Number(x) || 0);
    return absX <= 9499 ? roundUnder9499(x) : roundOver9499(x);
}

function renderProjectWithBreakout(content, y, projectBulletLevel, yearless) {
    const subBulletLevel = projectBulletLevel + 1;
    const openTotal = roundAmount(y.nonAnonAmountI || 0).roundedAmount;
    const anonTotal = roundAmount(y.anonAmountI  || 0).roundedAmount;
    const isMixed   = openTotal > 0 && anonTotal > 0;
    let parentText = `${y.projectName} ($${roundAmount(y.amountI).formattedAmount})`;
    if (!yearless) parentText += ` (${y.pledgeTimeFrame})`;
    if (!isMixed && y.anonymous) parentText += ' (Anonymous)';
    content.push(new docx.Paragraph({
        bullet: { level: projectBulletLevel },
        children: [new docx.TextRun({ text: parentText, font: font, size: 24 })]
    }));
    if (isMixed) {
        [
            { amount: openTotal, years: y.nonAnonTimeFrame, anon: false },
            { amount: anonTotal, years: y.anonTimeFrame,    anon: true  }
        ]
        .sort((a, b) => b.amount - a.amount)
        .forEach(sb => {
            let text = `$${roundAmount(sb.amount).formattedAmount}`;
            if (!yearless) text += ` (${sb.years})`;
            if (sb.anon) text += ' (Anonymous)';
            content.push(new docx.Paragraph({
                bullet: { level: subBulletLevel },
                children: [new docx.TextRun({ text: text, font: font, size: 24 })]
            }));
        });
    }
}

function pageFooter() {
    const footerTable = new docx.Table({
        rows: [
            new docx.TableRow({
                children: [
                    new docx.TableCell({
                        children: [new docx.Paragraph({
                            alignment: docx.AlignmentType.LEFT,
                            children: [
                                new docx.TextRun({
                                    children: ["Created By ", createdByUser , " (via BRM)"], font: font, size:18
                                }),
                            ],
                        }), new docx.Paragraph({
                            alignment: docx.AlignmentType.LEFT,
                            children: [
                                new docx.TextRun({
                                    children: ["On ", createdDate], font: font, size:18
                                }),
                            ],
                        })],
                        borders: {
                            top: {style: docx.BorderStyle.NONE, size: 0, color: "FFFFFF"},
                            bottom: {style: docx.BorderStyle.NONE, size: 0, color: "FFFFFF"},
                            left: {style: docx.BorderStyle.NONE, size: 0, color: "FFFFFF"},
                            right: {style: docx.BorderStyle.NONE, size: 0, color: "FFFFFF"},
                          },
                        width: {
                            size: 50,
                            type: docx.WidthType.PERCENTAGE,
                        }
                    }),
                    new docx.TableCell({
                        children: [new docx.Paragraph({
                            alignment: docx.AlignmentType.RIGHT,
                            children: [
                                new docx.TextRun({
                                    children: [docx.PageNumber.CURRENT ," of " ,docx.PageNumber.TOTAL_PAGES], font: font, size:18
                                })
                            ],
                        })],
                        borders: {
                            top: {style: docx.BorderStyle.NONE, size: 0, color: "FFFFFF"},
                            bottom: {style: docx.BorderStyle.NONE, size: 0, color: "FFFFFF"},
                            left: {style: docx.BorderStyle.NONE, size: 0, color: "FFFFFF"},
                            right: {style: docx.BorderStyle.NONE, size: 0, color: "FFFFFF"},
                          },
                        width: {
                            size: 50,
                            type: docx.WidthType.PERCENTAGE,
                        }
                    }),

                    
                ],
            }),
        ],
    });


    return {
        default: new docx.Footer({
        children: [footerTable],
        }),
    }

}

function saveFile(fileName , retURL , doc){
    docx.Packer.toBlob(doc).then(blob => {
        saveAs(blob, fileName);
  
        if( retURL !== '' ) {
            window.location.href = retURL;
        }
      });
}