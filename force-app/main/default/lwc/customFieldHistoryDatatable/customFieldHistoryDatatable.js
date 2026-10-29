import LightningDatatable from 'lightning/datatable';
import richTextCell from './richTextCell.html';

export default class CustomFieldHistoryDatatable extends LightningDatatable {
    static customTypes = {
        richText: {
            template: richTextCell,
            standardCellLayout: true,
            typeAttributes: ['isRichText'],
            cellAttributes: { style: 'vertical-align: top;' }
        }
    };
}