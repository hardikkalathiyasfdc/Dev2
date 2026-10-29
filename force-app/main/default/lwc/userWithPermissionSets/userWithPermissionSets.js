import { LightningElement, track, wire, api } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getAllUsersWithPermissionSets from '@salesforce/apex/UserWithPermissionSetsAuraCtrl.getAllUsersWithPermissionSets';
import deletePermissionSetAssginment from '@salesforce/apex/UserWithPermissionSetsAuraCtrl.deletePermissionSetAssginment';
import deletePublicGroupMembership from '@salesforce/apex/UserWithPermissionSetsAuraCtrl.deletePublicGroupMembership';
import LightningConfirm from 'lightning/confirm';

export default class userWithPermissionSets extends LightningElement {
	@api isInitiativeManagement = false;
	@track permissionSets;
	@track error;
	@track wiredPermissions;
	@track showCreation;
	@track initialRecords;
	sortcolumn;
	sortDirection = 'asc';
	showUserClone = false;
	records;
	showPermisionSetwithTeam = false;
	isSortTeam = false;
	isSortName = false;
	isSortPublicGroup = false;
	isSortLastLoginDate = false;
	isSortAssignedPS = false;
	isSortProfile = false;
	isLoading = true;
	columns = ['userName', 'team', 'profile', 'publicGroups', 'permissionSets'];

	@track selectedPS = new Set();
	@track selectedPublicGroups = new Set();

	get isButtonDisabled() {
		return this.selectedPS.size == 0 && this.selectedPublicGroups.size == 0;
	}
	connectedCallback() {
		this.showCreation = false;
	}

	handleSelection(event) {
		const id = event.target.dataset.id;
		const type = event.target.dataset.type;
		const checked = event.target.checked;
		if (type === 'ps') {
			const updated = new Set(this.selectedPS);
			checked ? updated.add(id) : updated.delete(id);
			this.selectedPS = updated;
		}

		if (type === 'pg') {
			const updated = new Set(this.selectedPublicGroups);
			checked ? updated.add(id) : updated.delete(id);
			this.selectedPublicGroups = updated;
		}
	}

	async handleBulkDelete() {
		const psCount = this.selectedPS.size;
		const pgCount = this.selectedPublicGroups.size;

		// Nothing selected
		if (psCount === 0 && pgCount === 0) {
			return;
		}

		const message =
			`You have selected ${psCount} Permission Set(s) and ${pgCount} Public Group(s) for deletion.\n\n` +
			`Deleting these may impact user access and permissions.\n\n` +
			`Are you sure you want to continue?`;

		const result = await LightningConfirm.open({
			message: message,
			variant: 'header',
			label: 'Confirm Delete',
			theme: 'warning',
		});

		// User clicked Cancel
		if (!result) {
			return;
		}

		this.isLoading = true;

		try {

			// Delete Permission Sets
			await Promise.all(
				[...this.selectedPS].map(id =>
					deletePermissionSetAssginment({ recordId: id })
				)
			);

			// Delete Public Groups
			await Promise.all(
				[...this.selectedPublicGroups].map(id =>
					deletePublicGroupMembership({ recordId: id })
				)
			);

			// Reset selections
			this.selectedPS = new Set();
			this.selectedGroups = new Set();
			this.selectedPublicGroups = new Set();

			await refreshApex(this.wiredPermissions);

		} catch (error) {
			this.error = error;
		} finally {
			this.isLoading = false;
		}
	}

	@wire(getAllUsersWithPermissionSets, { isInitiativeManagement: '$isInitiativeManagement' }) permissionSet(result) {
		this.wiredPermissions = result;
		if (result.data) {
			let tmpSets = JSON.parse(result.data);

			let allUserSets = [];

			Object.keys(tmpSets).forEach(key => {
				let tmpObj = {};
				tmpObj.key = key;
				tmpObj.url = '/' + key;
				tmpObj.permSetGroupAssignments = tmpSets[key].permSetGroupAssignments ? tmpSets[key].permSetGroupAssignments.filter(function (e1) {
					return e1.groupAssignment.PermissionSet.Label.substring(0, 3) !== '00e';
				}) : [];
				tmpObj.permSetGroupAssignments.sort((a, b) => {
					return a.groupAssignment.PermissionSet.Label > b.groupAssignment.PermissionSet.Label ? 1 : a.groupAssignment.PermissionSet.Label < b.groupAssignment.PermissionSet.Label ? -1 : 0;
				});
				tmpObj.permissionSets = tmpSets[key].assignments.filter(function (e1) {
					return e1.PermissionSet.Label.substring(0, 3) !== '00e';
				});

				tmpObj.permissionSets.sort((a, b) => {
					return a.PermissionSet.Label > b.PermissionSet.Label ? 1 : a.PermissionSet.Label < b.PermissionSet.Label ? -1 : 0;
				});

				tmpObj.customPermissions = (tmpSets[key].customPermissions || []).sort((a, b) => {
					return a.label > b.label ? 1 : a.label < b.label ? -1 : 0;
				});

				tmpObj.userName = tmpSets[key].u.Name;
				tmpObj.userTeam = tmpSets[key].u.BP_Team__c;
				tmpObj.team = tmpSets[key].u.Sharing_Team__c;
				tmpObj.profile = tmpSets[key].u.Profile.Name;

				let lstLoginDate = tmpSets[key].u.LastLoginDate;
				if (lstLoginDate !== undefined && lstLoginDate !== '') {
					let d = new Date(lstLoginDate);

					tmpObj.lastLoginDate = d.toLocaleString('en-US', { timeZone: 'America/New_York' });
				}

				tmpObj.publicGroups = tmpSets[key].groupMemberships;

				if (tmpObj.publicGroups !== undefined && tmpObj.publicGroups !== null) {
					tmpObj.publicGroups.sort((a, b) => {
						return a.userGroup.Name > b.userGroup.Name ? 1 : a.userGroup.Name < b.userGroup.Name ? -1 : 0;
					});
				}

				tmpObj.allAssignments = tmpSets[key].allAssignments ? tmpSets[key].allAssignments : [];
				if (tmpObj.allAssignments !== undefined && tmpObj.allAssignments !== null) {
					tmpObj.allAssignments.sort((a, b) => {
						return a.permissionSetLabel > b.permissionSetLabel ? 1 : a.permissionSetLabel < b.permissionSetLabel ? -1 : 0;
					});
				}
				// Permission Sets
				tmpObj.allAssignments = (tmpObj.allAssignments || []).map((item, i) => ({
					...item,
					rowIndex: i + 1
				}));

				// Custom Permissions
				tmpObj.customPermissions = (tmpObj.customPermissions || []).map((item, i) => ({
					...item,
					rowIndex: i + 1
				}));

				// Public Groups
				tmpObj.publicGroups = (tmpObj.publicGroups || []).map((item, i) => ({
					...item,
					rowIndex: i + 1
				}));

				allUserSets.push(tmpObj);
			});
			allUserSets.sort((a, b) => {

				return a.team > b.team ? 1 : a.team < b.team ? -1 : 0 || a.userName > b.userName ? 1 : a.userName < b.userName ? -1 : 0;
			});
			let idx = 1;
			allUserSets.forEach(x => {
				x.idx = idx;
				idx++;
			});
			this.permissionSets = allUserSets;
			this.records = allUserSets;
			this.initialRecords = allUserSets;
			this.error = undefined;
			this.isLoading = false;
		}
	}

	sortRecs(colName) {
		this.permissionSets = this.initialRecords;
		this.isLoading = true;
		if (this.sortedColumn === colName) {
			this.sortDirection = (this.sortDirection === 'asc' ? 'desc' : 'asc');
		}
		else {
			this.sortDirection = 'asc';
		}

		let sortBy = colName;

		let isReverse = this.sortDirection === 'asc' ? 1 : -1;
		this.sortedColumn = colName;

		let allUserSets = this.permissionSets;

		allUserSets.sort((a, b) => {
			a = a[colName] ? a[colName].toLowerCase() : '';
			b = b[colName] ? b[colName].toLowerCase() : '';

			return a > b ? 1 * isReverse : -1 * isReverse;
		});

		this.permissionSets = allUserSets;
	}

	sortTeam(event) {
		this.issortName = false;
		this.isSortAssignedPS = false;
		this.isSortLastLoginDate = false;
		this.isSortPublicGroup = false;
		this.issortprofile = false;
		this.issortTeam = true;
		this.sortRecs(event.currentTarget.dataset.id);
		this.isLoading = false;
	}

	sortName(event) {
		this.issortName = true;
		this.isSortAssignedPS = false;
		this.isSortLastLoginDate = false;
		this.isSortPublicGroup = false;
		this.issortprofile = false;
		this.issortTeam = false;
		this.sortRecs(event.currentTarget.dataset.id);
		this.isLoading = false;
	}


	sortProfile(event) {
		this.issortName = false;
		this.isSortAssignedPS = false;
		this.isSortLastLoginDate = false;
		this.isSortPublicGroup = false;
		this.issortprofile = true;
		this.issortTeam = false;
		this.sortRecs(event.currentTarget.dataset.id);
		this.isLoading = false;
	}


	sortAssignedPS(event) {
		this.issortName = false;
		this.isSortAssignedPS = true;
		this.isSortLastLoginDate = false;
		this.isSortPublicGroup = false;
		this.issortprofile = false;
		this.issortTeam = false;
		this.sortRecs(event.currentTarget.dataset.id);
		this.isLoading = false;
	}

	sortPublicGroup(event) {
		this.issortName = false;
		this.isSortAssignedPS = false;
		this.isSortLastLoginDate = false;
		this.isSortPublicGroup = true;
		this.issortprofile = false;
		this.issortTeam = false;
		this.sortRecs(event.currentTarget.dataset.id);
		this.isLoading = false;
	}

	sortLastLoginDate(event) {
		this.issortName = false;
		this.isSortAssignedPS = false;
		this.isSortLastLoginDate = true;
		this.isSortPublicGroup = false;
		this.issortprofile = false;
		this.issortTeam = false;
		this.sortRecs(event.currentTarget.dataset.id);
		this.isLoading = false;
	}

	handleDelete(event) {
		let permissionAssignmentId = event.target.id.split('-')[0];

		deletePermissionSetAssginment({ 'recordId': permissionAssignmentId })
			.then(result => {
				this.error = undefined;

				refreshApex(this.wiredPermissions);
			})
			.catch(error => {
				this.error = error;
			});
	}

	handleDeleteGroup(event) {
		let groupMembershipId = event.target.id.split('-')[0];

		deletePublicGroupMembership({ 'recordId': groupMembershipId })
			.then(result => {
				this.error = undefined;

				refreshApex(this.wiredPermissions);
			})
			.catch(error => {
				this.error = error;
			});
	}

	handleAddPermissionSetsCreation(event) {
		this.showCreation = true;
	}

	hancelModalCancel(event) {
		this.showCreation = false;
		this.showUserClone = false;
		this.showPermisionSetwithTeam = false;
		refreshApex(this.wiredPermissions);
	}

	handleUserPermissionClone(event) {
		this.showUserClone = true;
	}

	handlePermissionSetTeamUpdate(event) {
		this.showPermisionSetwithTeam = true;
	}

	handleSearchChange(event) {
		this.searchString = event.detail.value;
	}

	handleSearch(event) {
		this.permissionSets = this.initialRecords;
		let searchKey = event.detail.value.toLowerCase();
		if (searchKey) {
			let tmpSet = this.permissionSets.filter(function (item) {
				if (item.userName  && item.userName.toLowerCase().includes(searchKey)) {
					return true;
				}
				if (item.profile && item.profile.toLowerCase().includes(searchKey)) {
					return true;
				}
				if (item.userTeam && item.userTeam.toLowerCase().includes(searchKey)) {
					return true;
				}
				if (item.team && item.team.toLowerCase().includes(searchKey)) {
					return true;
				}
				if (item.permissionSets !== undefined) {
					var i;
					for (i = 0; i < item.permissionSets.length; i++) {
						if (item.permissionSets[i].PermissionSet.Label.toLowerCase().includes(searchKey)) {
							return true;
						}
					}
				}
				if (item.permSetGroupAssignments !== undefined) {
					var k;
					for (k = 0; k < item.permSetGroupAssignments.length; k++) {
						if (item.permSetGroupAssignments[k].groupAssignment.PermissionSet.Label.toLowerCase().includes(searchKey)) {
							return true;
						}
						if (item.permSetGroupAssignments[k].permissionSets) {
							for (var m = 0; m < item.permSetGroupAssignments[k].permissionSets.length; m++) {
								if (item.permSetGroupAssignments[k].permissionSets[m].Label.toLowerCase().includes(searchKey)) {
									return true;
								}
							}
						}
					}
				}
				if (item.publicGroups !== undefined && item.publicGroups !== null) {
					var j;
					for (j = 0; j < item.publicGroups.length; j++) {
						if (item.publicGroups[j].userGroup.Name.toLowerCase().includes(searchKey)) {
							return true;
						}
					}
				}
				if (item.customPermissions !== undefined && item.customPermissions !== null) {
					for (var c = 0; c < item.customPermissions.length; c++) {
						if (item.customPermissions[c].label && item.customPermissions[c].label.toLowerCase().includes(searchKey)) {
							return true;
						}
						if (item.customPermissions[c].permissionSetName && item.customPermissions[c].permissionSetName.toLowerCase().includes(searchKey)) {
							return true;
						}
					}
				}

				return false;
			});
			this.permissionSets = tmpSet;
		} else {
			this.permissionSets = this.initialRecords;
		}
	}
}