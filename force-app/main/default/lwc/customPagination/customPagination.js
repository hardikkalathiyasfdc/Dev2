import { LightningElement, api } from 'lwc';

export default class customPagination extends LightningElement {
    @api totalPages = 10;
    @api currentPage = 1;

    get isFirstPage() {
        return this.currentPage === 1;
    }

    get isLastPage() {
        return this.currentPage === this.totalPages;
    }

    get visiblePages() {
        const pages = [];
        const maxDisplayed = 5;
        const addPage =(num, isCurrent = false) => {
            pages.push({
                key: `page-${num}`,
                number: num,
                isEllipsis: false,
                class: `page-button ${this.currentPage === num ? 'active' : ''}`
            });
        };
        if(this.totalPages <= maxDisplayed + 2) {
            for(let i = 1; i <= this.totalPages; i++) addPage(i);
        } else {
            addPage(1);
            if(this.currentPage > 3) pages.push({ key: 'ellipsis-left', isEllipsis: true });
            const start = Math.max(2, this.currentPage - 1);
            const end = Math.min(this.totalPages - 1, this.currentPage + 1);
            for(let i = start; i <= end; i++) addPage(i);
            if(this.currentPage < this.totalPages - 2) 
                pages.push({ key: 'ellipsis-right', isEllipsis: true });
            addPage(this.totalPages);
        }
        return pages;
    }

    handlePageClick(event) {
        const selectedPage = parseInt(event.target.dataset.page, 10);
        this.currentPage = selectedPage;
        this.dispatchEvent(new CustomEvent('pagechange', { 
            detail: { page: selectedPage } 
        }));
    } 

    handlePrevious() {
        if(this.currentPage > 1) {
            this.currentPage -= 1;
            this.dispatchEvent(new CustomEvent('pagechange', { 
                detail: { page: this.currentPage } 
            }));
        }
    }

    handleNext() {
        if(this.currentPage < this.totalPages) {
            this.currentPage += 1;
            this.dispatchEvent(new CustomEvent('pagechange', { 
                detail: { page: this.currentPage } 
            }));
        }
    }
}