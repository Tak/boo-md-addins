namespace Boo.Ide

import Boo.Lang.Compiler.Ast

import Boo.Lang.Compiler.TypeSystem
import Boo.Lang.Compiler.TypeSystem.Core

import Boo.Adt
import Boo.Lang.PatternMatching

import System.Linq.Enumerable

data CompletionProposal(Entity as IEntity)

static class CompletionProposer:
	
	def ForExpression(expression as Expression):
		match expression:
			case MemberReferenceExpression(Target: Expression(ExpressionType)) and ExpressionType is not null:
				accessibleMembersByName = (member for member in AccessibleMembersOf(ExpressionType)).GroupBy({ member as IEntity | member.Name })
				for member in accessibleMembersByName:
					yield CompletionProposal(Entities.EntityFromList(member.ToList()))
			otherwise:
				pass
				
	def AccessibleMembersOf(type as IType):
		currentType = type
		while currentType is not null:
			for member in currentType.GetMembers():
				if IsSpecialName(member.Name):
					continue
				match member:
					case IConstructor():
						continue
					case IEvent():
						yield member
					case IAccessibleMember(IsPublic, IsStatic):
						if IsPublic and not IsStatic:
							yield member
					otherwise:
						continue
			currentType = currentType.BaseType
			
	_specialPrefixes = { "get_": 1, "set_": 1, "add_": 1, "remove_": 1, "op_": 1 }
	
	def IsSpecialName(name as string):
		index = name.IndexOf('_')
		return false if index < 0
		
		prefix = name[:index + 1]
		return prefix in _specialPrefixes

