import React, { useState } from "react";
import { UserFaction } from "../types/models";
import Button from "../common/Button";
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { byPrefixAndName } from '@awesome.me/kit-902717d512/icons';
import { apiCall } from "../utils/helpers";
import RichTextEditor from "../common/RichTextEditor";
import RichTextDisplay from "../common/RichTextDisplay";

type Props = {
  isCurrentUser: boolean;
  userFaction: UserFaction;
}

const UserFactionNotes = (props: Props) => {
  const [proposedNotes, setProposedNotes] = useState(props.userFaction.notes || '');

  const [saveButtonDisabled, setSaveButtonDisabled] = useState(false);
  const [error, setError] = useState('');

  async function saveUserFaction() {
    try {
      apiCall({
        endpoint: '/user-factions/'+props.userFaction.id,
        method: 'PUT',
        body: {
          notes: proposedNotes
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

  const componentId = 'user-faction-notes';

  return (
    <div id={componentId}>
      <div className='mt-5'>
        {props.isCurrentUser &&
          <>
            <RichTextEditor
              value={proposedNotes}
              onChange={setProposedNotes}
              className='mb-5' />

            <div className='flex items-center'>
              <Button onClick={saveUserFaction} disabled={saveButtonDisabled} className='max-w-[170px] mx-auto'>
                <FontAwesomeIcon icon={byPrefixAndName.fas['floppy-disk']} className='mr-2' />
                Save
              </Button>
            </div>

            <div className='text-center text-red-500'>{error}</div>
          </>
        }
        {!props.isCurrentUser &&
          <RichTextDisplay content={proposedNotes} />
        }
      </div>
    </div>
  );
};

export default UserFactionNotes;
