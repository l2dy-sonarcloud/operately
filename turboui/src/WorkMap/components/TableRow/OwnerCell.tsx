import React from "react";
import { AvatarWithName } from "../../../Avatar/AvatarWithName";
import { WorkMap } from "..";
import { useItemStatus } from "../../hooks/useItemStatus";
import classNames from "../../../utils/classnames";

interface Props {
  item: WorkMap.Item;
  hide?: boolean;
}

export function OwnerCell({ item, hide }: Props) {
  const { isCompleted, isFailed, isDropped, isPending } = useItemStatus(item.status);

  const className = classNames(
    "text-sm truncate hover:underline transition-colors whitespace-nowrap overflow-hidden text-ellipsis inline-block",
    isCompleted || isFailed ? "text-content-dimmed" : "text-content-base hover:text-link-hover",
    isDropped && "opacity-70 text-content-dimmed",
    isPending && "text-content-dimmed",
  );

  if (hide) return null;

  if (!item.owner) return <td />;

  return (
    <td className="py-2 px-2 md:px-4 hidden xl:table-cell">
      <div className="max-w-[120px] overflow-hidden">
        <AvatarWithName
          person={item.owner}
          size="tiny"
          nameFormat="short"
          className={className}
          link={item.ownerPath || undefined}
        />
      </div>
    </td>
  );
}
