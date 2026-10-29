import { LightningElement, track, wire, api } from 'lwc';
import getPhotos from '@salesforce/apex/PhotosViewerAuraCtrl.getPhotos';

export default class photosViewer extends LightningElement {

	@api libName;
	@api interval;

	error;
	photo;

	connectedCallback() {
		getPhotos({ libName: this.libName })
		.then( result => {

			let allPhotos = JSON.parse(result);
			allPhotos.forEach(item => {
				item.url = '/sfc/servlet.shepherd/version/download/'+item.Id;
			});

			let idx = 0;
			let interalVal = this.interval * 1000;
			this.photo = allPhotos[idx];
			setInterval(() => {
				idx++;
				if (idx === allPhotos.length) {
					idx = 0;
				}
				this.photo = allPhotos[idx];
			}, interalVal);
			this.error = undefined;
		})
		.catch( error => {
			this.error = error;
			this.error = undefined;
		})
	}
}