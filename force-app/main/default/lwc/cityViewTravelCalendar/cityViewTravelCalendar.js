import { LightningElement, track, wire, api } from 'lwc';
import getCityViewTravelDetails from '@salesforce/apex/CityViewDetailPageController.getCityViewTravelDetails';
import { NavigationMixin } from 'lightning/navigation';
import hasCustomPermission from '@salesforce/customPermission/CityView_With_Clickthrus';
import hasEmployeeTravelPermission from '@salesforce/customPermission/CityView_Employee_Travel_Custom_Permission';
export default class CityViewTravelCalendar extends LightningElement {

    @track error;
    isLoading = false;
    _selectedGeoAreaId;
    @track isGeoAreaIdAvailable = false;
    hasPermission = false;
    travelDetails = [];
    monthMap = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    @api
    get geoAreaId() {
        return this._selectedGeoAreaId;
    }

    @api
    getEventsData() {
        //if(hasEmployeeTravelPermission)
        //return this.travelDetails;
    }

    set geoAreaId(value) {
        this.isGeoAreaIdAvailable = !!value;
        if (value !== this._selectedGeoAreaId) {
            this.fetchTravelDetails(value);
        }
        this._selectedGeoAreaId = value;
    }

    get showTravelDetails() {
        return this.travelDetails.length > 0;
    }

    @api formFactor;

    get tableStyle() {
        const normalizedFormFactor = this.formFactor ? this.formFactor.toLowerCase() : '';
        if (normalizedFormFactor === 'large') {
            return 'max-height: 300px; overflow: auto;';
        } else {
            return '';
        }
    }

    fetchTravelDetails(geoAreaId) {
        this.isLoading = true;
        getCityViewTravelDetails({ geoAreaId })
            .then(result => {
                this.travelDetails = result.map(event => ({
                    ...event,
                    formattedStartDate: this.formatDate(event.StartDateTime),
                    formattedEndDate: this.formatDate(event.EndDateTime),
                    showDescription: false,
                    descKey: event.Id + '_desc',
                    displayDescription: event.Description && event.Description.trim() !== ''
                        ? event.Description
                        : 'No Employee travel description at this time'
                }));
            })
            .catch(error => {
                console.error('Error fetching travel details:', error);
                this.error = error;
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    formatDate(dateStr) {
        if (!dateStr) return '';
        const options = { year: 'numeric', month: 'short', day: 'numeric', timeZone: 'UTC' };
        const date = new Date(dateStr);
        return new Intl.DateTimeFormat('en-US', options).format(date);
    }

    handleShowDescription(event) {
        const recordId = event.target.dataset.id;

        this.travelDetails = this.travelDetails.map(ev => ({
            ...ev,
            showDescription: ev.Id === recordId ? !ev.showDescription : ev.showDescription
        }));
    }

}