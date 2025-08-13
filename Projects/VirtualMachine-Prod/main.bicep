
import { regionType } from '../../../modules/.shared/commonTypes.bicep'
import { OSType } from '../../../modules/.shared/commonTypes.bicep'
import { vmSizeType } from '../../modules/.shared/commonTypes.bicep'
param SizeOfVM vmSizeType
param TypeofOS OSType
param VMName string
param regionAbbreviation regionType
param subnetName string
param vNetRG string
param vNetName string


module DeployVM '../../../modules/deployVM.bicep' = {
  params: {
    SizeOfVM: SizeOfVM
    TypeofOS: TypeofOS
    VMName: VMName
    regionAbbreviation: regionAbbreviation
    subnetName: subnetName
    vNetRG: vNetRG
    vNetName: vNetName
  }
}
