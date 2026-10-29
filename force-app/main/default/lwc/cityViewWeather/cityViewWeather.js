import { LightningElement, api } from 'lwc';
import getWeatherData from '@salesforce/apex/CityViewWeatherController.getWeatherData';
import WEATHER_ICONS from '@salesforce/resourceUrl/WeatherIcons';

export default class CityViewWeather extends LightningElement {
    temperature = '';
    weatherDescription = '';
    iconUrl = '';
    localTime = '';
    latitude_ = '';
    longitude_ = '';
    isLocationAvailable = false;

    @api
    get latitude() {
        return this.latitude_;
    }
    set latitude(value) {
        this.isLocationAvailable = !!value;
        if(value !== this.latitude_) {
            this.latitude_ = value;
        }
    }

    @api
    get longitude() {
        return this.longitude_;
    }
    set longitude(value) {
        this.isLocationAvailable = !!value;
        if(value !== this.longitude_) {
            this.longitude_ = value;
            this.fetchWeatherData();
        }
    }

    connectedCallback() {
        this.fetchWeatherData();
    }

    async fetchWeatherData() {
        await getWeatherData({ 
            latitude: this.latitude,
            longitude: this.longitude 
        }).then(result => {
            const daypart = result?.weather?.daypart?.[0];
            if(daypart && daypart.temperature && daypart.wxPhraseLong) {
                const temperatureToday = daypart.temperature[0];
                const weatherDescriptionToday = daypart.wxPhraseLong[0];
                const iconCode = daypart.iconCode[0];
                if(temperatureToday && weatherDescriptionToday) {
                    this.temperature = temperatureToday;
                    this.weatherDescription = weatherDescriptionToday;
                }
                if(iconCode) this.iconUrl = `${WEATHER_ICONS}/PNGs/${iconCode}.png`;
            }
            const validTime = result?.weather?.validTimeLocal;
            if(validTime) {
                let localTime = validTime[0];
                let dayOfWeek = result?.weather?.dayOfWeek[0];
                const offsetStr = localTime.slice(-5);
                const sign = offsetStr[0] === '+' ? 1 : -1;
                const hours = parseInt(offsetStr.slice(1, 3), 10);
                const minutes = parseInt(offsetStr.slice(3, 5), 10);
                const offsetInHours = sign * (hours + minutes / 60);
                const now = new Date();
                const utcTime = now.toISOString();
                const utcDate = new Date(utcTime);
                const convertedDate = new Date(utcDate.getTime() + offsetInHours * 60 * 60 * 1000);
                const convertedTime = convertedDate.toISOString();
                this.localTime = dayOfWeek.substring(0, 3) + ', ' + this.formatIsoStringManually(convertedTime);
            }
        }).catch(error => {
            console.error('#### error - ' + JSON.stringify(error.body));
        });
    }

    formatIsoStringManually(isoString) {
        const [datePart, timePartWithMsZ] = isoString.split('T');
        const [year, month, day] = datePart.split('-');
        const [timePart] = timePartWithMsZ.split('.');
        let [hour, minute, second] = timePart.split(':');
        let hourNumber = parseInt(hour, 10);
        const ampm = hourNumber >= 12 ? 'PM' : 'AM';
        hourNumber = hourNumber % 12 || 12;
        const monthNames = [
            "January", "February", "March", "April", "May", "June",
            "July", "August", "September", "October", "November", "December"
        ];
        const monthName = monthNames[parseInt(month, 10) - 1];
        return `${monthName} ${parseInt(day)}, ${year} ${hourNumber}:${minute} ${ampm}`;
    }
}