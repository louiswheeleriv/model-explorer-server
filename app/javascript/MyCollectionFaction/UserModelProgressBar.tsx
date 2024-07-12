import React, { useState, useEffect} from "react";
import { Model, QuantityByStatus, UserModel } from "../types/models";
import StatusColorBar from "../common/StatusColorBar";
import $ from 'jquery';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { byPrefixAndName } from '@awesome.me/kit-902717d512/icons';
import { apiCall, countByStatus } from "../utils/helpers";
import UserModelStatusEditor from "../common/UserModelStatusEditor";
import Button from "../common/Button";

type Props = {
  model: Model;
  userModel: UserModel;
  startExpanded?: boolean;
  className?: string;
}

const UserModelProgressBar = (props: Props) => {
  const numByStatus = countByStatus([props.userModel]);
  const initialDraftQuantityByStatus = {
    unassembled: numByStatus.unassembled,
    assembled: numByStatus.assembled,
    in_progress: numByStatus.in_progress,
    finished: numByStatus.finished
  };

  const [isExpanded, setIsExpanded] = useState(props.startExpanded != undefined ? props.startExpanded : false);
  const [draftQuantityByStatus, setDraftQuantityByStatus] = useState<QuantityByStatus>(initialDraftQuantityByStatus);
  const [selectedImage, setSelectedImage] = useState<File | null>(null);
  const [error, setError] = useState('');

  useEffect(() => {
    const marginTop = isExpanded ? '0' : '-100vh';
    const opacity = isExpanded ? '100%' : 0;
    const angle = isExpanded ? 90 : 0;
    $('#'+componentId+' .model-status-editor').css({
      'margin-top': marginTop,
      'opacity': opacity
    });
    $('#'+componentId+' .collapse-icon').css({ 'transform': 'rotate('+angle+'deg)' });
    if (!isExpanded) setDraftQuantityByStatus(initialDraftQuantityByStatus);
  }, [isExpanded]);

  useEffect(() => {
  }, [draftQuantityByStatus])

  async function saveUserModel() {
    try {
      apiCall({
        endpoint: '/my_collection/factions/'+props.model.faction_id+'/models/'+props.model.id,
        method: 'PUT',
        body: {
          quantity_by_status: {
            unassembled: draftQuantityByStatus.unassembled,
            assembled: draftQuantityByStatus.assembled,
            in_progress: draftQuantityByStatus.in_progress,
            finished: draftQuantityByStatus.finished
          }
        }
      })
        .then((response) => response.json())
        .then((body) => {
          if (body.status >= 300) throw new Error(body.error)
          location.reload();
        });
    } catch(err) {
      if (err instanceof Error) setError(err.message);
    }
  }

  async function uploadImage() {
    try {
      const presignedUrl = await getPresignedUrl();
      const assetUrl = await uploadAssetToS3(presignedUrl);
      await createImage(assetUrl);
    } catch(err) {
      if (err instanceof Error) setError(err.message);
    }
  }

  async function getPresignedUrl(): Promise<string> {
    return apiCall({
      endpoint: '/user_assets/upload',
      method: 'GET'
    })
      .then((response) => response.json())
      .then((body) => {
        if (body.status >= 300) throw new Error(body.error)
        return body.presigned_url;
      });
  }

  async function uploadAssetToS3(presignedUrl: string) {
    const response = await fetch(presignedUrl, {
      method: 'PUT',
      headers: { 'Content-Type': 'multipart/form-data' },
      body: selectedImage
    });
    return response.url.split('?')[0];
  }

  async function createImage(assetUrl: string) {
    apiCall({
      endpoint: '/user_assets/upload',
      method: 'POST',
      body: {
        asset_url: assetUrl,
        user_model_id: props.userModel.id
      }
    })
      .then((response) => response.json())
      .then((body) => {
        if (body.status >= 300) throw new Error(body.error)
        location.reload();
      });
  }

  async function handleFileSelected(e: React.ChangeEvent<HTMLInputElement>) {
    const selectedFiles = e.target.files as FileList;
    setSelectedImage(selectedFiles?.[0])
  }

  const componentId = 'user-model-' + props.userModel.id;

  return (
    <div className={props.className} id={componentId}>
      <div className='p-4 bg-[#607499] rounded-t-md flex cursor-pointer items-center' onClick={() => setIsExpanded(!isExpanded)}>
        <FontAwesomeIcon icon={byPrefixAndName.fas['chevron-right']}  className='collapse-icon transition-transform duration-300 mr-3' />
        {
          props.userModel.name ?
          (props.userModel.name+' ('+props.model.name+')') :
          props.model.name
        }
      </div>

      <div className='overflow-hidden'>
        <div className='model-status-editor bg-[#333a46] mt-[-100vh] p-5 opacity-0 transition-all duration-500'>
          <UserModelStatusEditor 
            quantityByStatus={draftQuantityByStatus}
            onChange={setDraftQuantityByStatus} />

          <div className='flex items-center mt-5'>
            <Button onClick={saveUserModel} className='max-w-[170px] mx-auto'>
              <FontAwesomeIcon icon={byPrefixAndName.fas['paintbrush-fine']} className='mr-2' />
              Save Model(s)
            </Button>
            <div className='text-red-500 text-center'>{error}</div>
          </div>

          {/* Example for file upload */}
          {/* <div className='flex items-center mt-5'>
            <label htmlFor="myfile">Select image:</label>
            <input type="file" id="myfile" name="myfile" accept="image/*" onChange={handleFileSelected} />

            <Button onClick={uploadImage} className='max-w-[170px] mx-auto'>
              <FontAwesomeIcon icon={byPrefixAndName.fas['paintbrush-fine']} className='mr-2' />
              Upload
            </Button>
          </div> */}
        </div>
      </div>

      <StatusColorBar numByStatus={numByStatus} rounding='bottom' size='small' />
    </div>
  );
};

export default UserModelProgressBar;
