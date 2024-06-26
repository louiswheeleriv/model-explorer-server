import React, { Fragment, useState, useEffect } from "react";
import { GameSystem, Faction } from "../types/models";
import FactionProgressBar from "./FactionProgressBar";
import $ from 'jquery';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { byPrefixAndName } from '@awesome.me/kit-902717d512/icons';

const GameSystemSection = ({ gameSystem, factionSections, startExpanded = true, className }: {
  gameSystem: GameSystem;
  factionSections: {
    faction: Faction;
    factionNumByStatus: Record<string, number>;
  }[];
  startExpanded: boolean;
  className?: string;
}) => {
  const [isExpanded, setIsExpanded] = useState(startExpanded);

  useEffect(() => {
    const marginTop = isExpanded ? '0' : '-100%';
    const angle = isExpanded ? 0 : -90;
    $('#'+componentId+' .faction-sections').css({ 'margin-top': marginTop });
    $('#'+componentId+' .collapse-icon').css({ 'transform': 'rotate('+angle+'deg)' })
  }, [isExpanded]);

  const componentId = 'game-system-section-' + gameSystem.id;

  return (
    <div className={className} id={componentId}>
      <div className='mb-5 text-xl w-fit cursor-pointer' onClick={() => setIsExpanded(!isExpanded)}>
        <span className='mr-3'>
          <FontAwesomeIcon icon={byPrefixAndName.fas['chevron-down']} className='collapse-icon transition-transform duration-300' />
        </span>
        {gameSystem.name}
      </div>
      <div className='faction-sections-container overflow-hidden'>
        <div className='faction-sections transition-margin-top duration-1000 delay-0'>
          {factionSections.map((factionSection) => (
            <Fragment key={factionSection.faction.id}>
              <FactionProgressBar
                faction={factionSection.faction}
                numByStatus={factionSection.factionNumByStatus}
                className='mb-5'/>
            </Fragment>
          ))}
        </div>
      </div>
    </div>
  );
};

export default GameSystemSection;
