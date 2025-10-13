import React, { useState } from "react";
import { UserFaction, GameSystem, Faction, Model, UserModel, User } from "../types/models";
import { countByStatus } from "../utils/helpers";
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { byPrefixAndName } from '@awesome.me/kit-902717d512/icons';
import Button from "../common/Button";

import SummaryProgressBar from "../common/SummaryProgressBar";
import GameSystemSection from "./GameSystemSection";
import AddFactionModal from "./AddFactionModal";

type Props = {
  user: User;
  user_factions: UserFaction[];
  user_models: UserModel[];
  models: Model[];
  all_factions: Faction[];
  factions: Faction[];
  all_game_systems: GameSystem[];
  user_game_systems: GameSystem[];
  num_images_by_user_faction_id: Record<number, number>;
};

const Collection = (props: Props) => {
  const [addFactionModalVisible, setAddFactionModalVisible] = useState(false);

  const numByStatus = countByStatus(props.user_models);
  const totalNumModels = Object.values(numByStatus).reduce((acc, num) => acc + num);
  
  const valueByLabel = {
    'Factions': props.user_factions.length,
    'Models': props.user_models.reduce((acc, um) => (
      acc + um.qty_unassembled + um.qty_assembled + um.qty_in_progress + um.qty_finished
    ), 0),
    'Complete': totalNumModels > 0 ? Math.round(((numByStatus['finished'] / totalNumModels) * 100)) + '%' : '0%'
  }

  const factionById = props.all_factions.reduce((acc: Record<number, Faction>, faction) => {
    acc[faction.id] = faction;
    return acc;
  }, {});

  const userModelsByUserFactionId = props.user_models.reduce((acc: Record<number, UserModel[]>, userModel) => {
    const key = userModel.user_faction_id;
    if (!acc[key]) acc[key] = [];
    acc[key].push(userModel);
    return acc;
  }, {});

  const gameSystemSections = props.user_game_systems.map((gameSystem) => {
    const userFactionSections =
      props.user_factions
        .filter((userFaction) => factionById[userFaction.faction_id]?.game_system_id === gameSystem.id)
        .map((userFaction) => {
          const userFactionUserModels = userModelsByUserFactionId[userFaction.id] || [];
          return {
            faction: factionById[userFaction.faction_id],
            userFaction: userFaction,
            factionNumByStatus: countByStatus(userFactionUserModels),
            numImages: props.num_images_by_user_faction_id[userFaction.id] || 0
          };
        })
        .sort((a, b) => {
          const aNumModels = Object.values(a.factionNumByStatus).reduce((acc, n) => acc + n);
          const bNumModels = Object.values(b.factionNumByStatus).reduce((acc, n) => acc + n);
          // Sort by num models descending
          if (aNumModels > bNumModels) return -1;
          if (aNumModels < bNumModels) return 1;
          if (a.faction.name < b.faction.name) return -1;
          if (a.faction.name > b.faction.name) return 1;
          return 0;
        });
    return {
      gameSystem: gameSystem,
      userFactionSections: userFactionSections,
    };
  });

  return (
    <div className='px-6 py-8 max-w-[600px] mx-auto'>
      <h2 className='text-2xl text-center mb-5'>My Collection</h2>

      <SummaryProgressBar
        numByStatus={numByStatus}
        valueByLabel={valueByLabel}
      />

      <div className='flex mt-5'>
        <div className='flex-1 text-end'>
          <Button onClick={() => setAddFactionModalVisible(true)}>
            <FontAwesomeIcon icon={byPrefixAndName.fas['flag']} className='mr-2' />
            New Faction
          </Button>
        </div>
      </div>
      <AddFactionModal
        visible={addFactionModalVisible}
        onClose={() => setAddFactionModalVisible(false)}
        userFactions={props.user_factions}
        allFactions={props.all_factions}
        allGameSystems={props.all_game_systems} />

      {gameSystemSections.map((gameSystemSection) => (
        <GameSystemSection
          key={gameSystemSection.gameSystem.id}
          gameSystem={gameSystemSection.gameSystem}
          userFactionSections={gameSystemSection.userFactionSections}
          startExpanded={true}
          className='mt-5'/>
      ))}
    </div>
  );
};

export default Collection;
